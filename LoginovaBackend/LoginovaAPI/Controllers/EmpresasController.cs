using System.Text;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Panel de Soporte: administra las empresas (tenants) del sistema
/// multi-tenant — altas (junto con el primer Administrador de cada una),
/// edición de membresía, y activación/suspensión. Exclusivo del rol
/// "Soporte", que no pertenece a ninguna empresa y por eso no está sujeto a
/// los filtros de consulta globales de <see cref="AppDbContext"/> (que solo
/// aplican a las entidades <see cref="ITenantOwned"/>, no a <see cref="Empresa"/> misma).
/// </summary>
[ApiController]
[Authorize(Roles = "Soporte")]
[Route("api/[controller]")]
public class EmpresasController : ControllerBase
{
    private static readonly TimeSpan VentanaPorVencer = TimeSpan.FromDays(7);

    private readonly AppDbContext _context;
    private readonly PasswordHasher _passwordHasher;
    private readonly AuditoriaService _auditoria;
    private readonly ITenantContext _tenant;

    public EmpresasController(AppDbContext context, PasswordHasher passwordHasher, AuditoriaService auditoria, ITenantContext tenant)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _auditoria = auditoria;
        _tenant = tenant;
    }

    [HttpGet]
    public async Task<ActionResult<List<EmpresaResponse>>> GetAll()
    {
        var empresas = await _context.Empresas
            .AsNoTracking()
            .OrderBy(empresa => empresa.FechaFinMembresia)
            .ToListAsync();

        return Ok(empresas.Select(ToResponse).ToList());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EmpresaResponse>> GetById(int id)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        return empresa is null ? NotFound() : Ok(ToResponse(empresa));
    }

    /// <summary>Crea una empresa nueva junto con su primer Administrador, en dos pasos
    /// (primero la empresa para obtener su Id, luego el usuario ya con ese Id) para no
    /// depender de que EF resuelva la FK a través de la navegación antes de que corra
    /// la red de seguridad de <see cref="AppDbContext.SaveChangesAsync"/>.</summary>
    [HttpPost]
    public async Task<ActionResult<EmpresaResponse>> Create(CrearEmpresaRequest request)
    {
        var correoDuplicado = await _context.Usuarios
            .IgnoreQueryFilters()
            .AnyAsync(u => u.EmpresaId != null && u.Correo == request.AdminCorreo);
        // La unicidad real es (EmpresaId, Correo), así que un correo repetido entre
        // empresas distintas es válido; este chequeo es solo una guía útil para
        // Soporte por si reutiliza sin querer el correo de una empresa que ya existe,
        // no una restricción de negocio.

        var empresa = new Empresa
        {
            NombreEmpresa = request.NombreEmpresa,
            NombreContacto = request.NombreContacto,
            TelefonoContacto = request.TelefonoContacto,
            CorreoContacto = request.CorreoContacto,
            FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc),
            FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc),
            MontoMembresia = request.MontoMembresia,
            CicloPago = request.CicloPago,
            Notas = request.Notas,
            Activa = true,
        };
        _context.Empresas.Add(empresa);
        await _context.SaveChangesAsync();

        var role = await _context.Roles.SingleAsync(r => r.Nombre == "Administrador");
        var admin = new Usuario
        {
            EmpresaId = empresa.Id,
            Nombre = request.AdminNombre,
            Correo = request.AdminCorreo,
            Password = _passwordHasher.Hash(request.AdminPassword),
            RoleId = role.Id,
            PermisosJson = "[]",
        };
        _context.Usuarios.Add(admin);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            "CREATE",
            null,
            new { empresa.NombreEmpresa, empresa.FechaInicioMembresia, empresa.FechaFinMembresia, AdminCorreo = admin.Correo },
            $"Nueva empresa registrada: {empresa.NombreEmpresa}{(correoDuplicado ? " (correo de admin repetido con otra empresa)" : "")}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(GetById), new { id = empresa.Id }, ToResponse(empresa));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, ActualizarEmpresaRequest request)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        var valoresAnteriores = new { empresa.FechaFinMembresia, empresa.Activa };

        empresa.NombreEmpresa = request.NombreEmpresa;
        empresa.NombreContacto = request.NombreContacto;
        empresa.TelefonoContacto = request.TelefonoContacto;
        empresa.CorreoContacto = request.CorreoContacto;
        empresa.FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc);
        empresa.FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc);
        empresa.MontoMembresia = request.MontoMembresia;
        empresa.CicloPago = request.CicloPago;
        empresa.Notas = request.Notas;

        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            "UPDATE",
            valoresAnteriores,
            new { empresa.FechaFinMembresia, empresa.Activa },
            $"Empresa actualizada: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    /// <summary>Activa la empresa: sus usuarios recuperan acceso de inmediato.</summary>
    [HttpPut("{id:int}/activar")]
    public async Task<IActionResult> Activar(int id) => await CambiarActiva(id, true);

    /// <summary>Suspende la empresa: TODOS sus usuarios (admin, operadores, etc.)
    /// pierden acceso de inmediato, sin importar el vencimiento de membresía.</summary>
    [HttpPut("{id:int}/suspender")]
    public async Task<IActionResult> Suspender(int id) => await CambiarActiva(id, false);

    private async Task<IActionResult> CambiarActiva(int id, bool activa)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        empresa.Activa = activa;
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            activa ? "ACTIVAR" : "SUSPENDER",
            null,
            new { empresa.Activa },
            $"Empresa {(activa ? "activada" : "suspendida")}: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return Ok(ToResponse(empresa));
    }

    /// <summary>Marca que se le envió un recordatorio manual (WhatsApp, llamada, etc.) a la empresa hoy.</summary>
    [HttpPut("{id:int}/recordatorio-enviado")]
    public async Task<IActionResult> MarcarRecordatorioEnviado(int id)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        empresa.UltimoRecordatorioEnviado = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(ToResponse(empresa));
    }

    /// <summary>
    /// Usuarios de una empresa específica, con sus permisos. Para investigar un
    /// caso de soporte sin depender de que el cliente mande capturas de
    /// pantalla. Soporte "impersona" el tenant de la empresa (mismo mecanismo
    /// que usa <see cref="IngresosController.CierreAutomatico"/>) para
    /// reutilizar el filtro de aislamiento normal en vez de saltárselo a
    /// mano: esto se ve reflejado en el resto del request (incluida la
    /// auditoría, que queda estampada con esta empresa, visible para su
    /// propio administrador).
    /// </summary>
    [HttpGet("{id:int}/usuarios")]
    public async Task<ActionResult<List<UsuarioResponse>>> UsuariosDeEmpresa(int id)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var usuarios = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Role)
            .Select(u => new UsuarioResponse(u.Id, u.Nombre, u.Correo, u.Rol, u.Permisos, u.Activo))
            .ToListAsync();

        return Ok(usuarios);
    }

    /// <summary>
    /// Corrige los permisos de un usuario de una empresa específica: el caso
    /// típico es un administrador que se bloqueó a sí mismo un permiso por
    /// error, o un operador mal configurado, y pide ayuda a Soporte para
    /// arreglarlo sin tener que esperar a que el propio administrador lo haga.
    /// </summary>
    [HttpPut("{id:int}/usuarios/{usuarioId:int}/permisos")]
    public async Task<IActionResult> ActualizarPermisosUsuario(int id, int usuarioId, ActualizarPermisosRequest request)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        if (!PermisosService.SonPermisosValidos(request.Permisos))
        {
            return BadRequest(new { mensaje = "Uno o más permisos no son válidos" });
        }

        _tenant.EmpresaId = id;

        // Where(...).FirstOrDefaultAsync() en vez de FindAsync: así se
        // fuerza siempre una consulta nueva con el filtro de tenant recién
        // asignado, sin depender de si FindAsync resuelve desde el
        // change tracker (que podría no respetar el filtro si el usuario
        // ya estuviera trackeado de una consulta anterior en el mismo
        // request).
        var usuario = await _context.Usuarios.Where(u => u.Id == usuarioId).FirstOrDefaultAsync();
        if (usuario is null)
        {
            return NotFound(new { mensaje = "Usuario no existe en esta empresa" });
        }

        var valoresAnteriores = new { Permisos = usuario.Permisos };
        usuario.EstablecerPermisos(PermisosService.NormalizarPermisos(request.Permisos));
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            usuario.Id,
            "UPDATE_PERMISOS_SOPORTE",
            valoresAnteriores,
            new { Permisos = usuario.Permisos },
            $"Soporte actualizó los permisos de {usuario.Nombre}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    /// <summary>
    /// Panorama rápido de actividad de una empresa (cuánta gente, cuánto
    /// movimiento y cuándo fue la última recogida), para que Soporte pueda
    /// diagnosticar un caso o detectar una empresa inactiva sin tener que
    /// recorrer manualmente cada módulo.
    /// </summary>
    [HttpGet("{id:int}/resumen")]
    public async Task<ActionResult<ResumenSoporteEmpresaResponse>> ResumenEmpresa(int id)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var totalUsuarios = await _context.Usuarios.CountAsync();
        var totalClientes = await _context.Clientes.CountAsync();
        var totalRecogidas = await _context.Recogidas.CountAsync();
        var recogidasPendientes = await _context.Recogidas.CountAsync(r => r.Estado == "Pendiente");
        var totalIngresos = await _context.Ingresos.CountAsync();
        var montoTotalIngresos = await _context.Ingresos.SumAsync(i => (decimal?)i.Monto) ?? 0m;
        var ultimaRecogida = await _context.Recogidas
            .OrderByDescending(r => r.FechaCreacion)
            .Select(r => (DateTime?)r.FechaCreacion)
            .FirstOrDefaultAsync();

        return Ok(new ResumenSoporteEmpresaResponse(
            totalUsuarios,
            totalClientes,
            totalRecogidas,
            recogidasPendientes,
            totalIngresos,
            montoTotalIngresos,
            ultimaRecogida));
    }

    /// <summary>
    /// Historial de auditoría de una empresa específica (quién cambió qué y
    /// cuándo), para que Soporte pueda investigar un caso sin depender de lo
    /// que el cliente recuerde o le cuente. Misma impersonación de tenant
    /// que el resto de endpoints de esta sección.
    /// </summary>
    [HttpGet("{id:int}/auditoria")]
    public async Task<ActionResult<List<AuditoriaLog>>> AuditoriaDeEmpresa(int id, [FromQuery] int limit = 100)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var logs = await _context.Auditoria
            .AsNoTracking()
            .OrderByDescending(l => l.FechaCambio)
            .Take(Math.Clamp(limit, 1, 500))
            .ToListAsync();

        return Ok(logs);
    }

    /// <summary>
    /// Restablece la contraseña de un usuario de una empresa a una temporal
    /// generada al azar, para el caso de un administrador u operador que
    /// quedó bloqueado (p. ej. correo mal configurado, no le llega el código
    /// de recuperación). La contraseña en claro solo se devuelve en esta
    /// respuesta, una sola vez: Soporte debe comunicarla al cliente y
    /// pedirle que la cambie de inmediato.
    /// </summary>
    [HttpPost("{id:int}/usuarios/{usuarioId:int}/restablecer-password")]
    public async Task<ActionResult<RestablecerPasswordResponse>> RestablecerPassword(int id, int usuarioId)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        // Where(...).FirstOrDefaultAsync() en vez de FindAsync: así se
        // fuerza siempre una consulta nueva con el filtro de tenant recién
        // asignado, sin depender de si FindAsync resuelve desde el
        // change tracker (que podría no respetar el filtro si el usuario
        // ya estuviera trackeado de una consulta anterior en el mismo
        // request).
        var usuario = await _context.Usuarios.Where(u => u.Id == usuarioId).FirstOrDefaultAsync();
        if (usuario is null)
        {
            return NotFound(new { mensaje = "Usuario no existe en esta empresa" });
        }

        var passwordTemporal = GenerarPasswordTemporal();
        usuario.Password = _passwordHasher.Hash(passwordTemporal);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            usuario.Id,
            "RESET_PASSWORD_SOPORTE",
            null,
            new { Motivo = "Contraseña restablecida por Soporte" },
            $"Soporte restableció la contraseña de {usuario.Nombre}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return Ok(new RestablecerPasswordResponse(passwordTemporal));
    }

    /// <summary>Genera una contraseña temporal de 12 caracteres, evitando símbolos ambiguos (0/O, 1/l/I) para que sea fácil de dictar o transcribir.</summary>
    private static string GenerarPasswordTemporal()
    {
        const string caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
        var bytes = System.Security.Cryptography.RandomNumberGenerator.GetBytes(12);
        var chars = new char[12];
        for (var i = 0; i < 12; i++)
        {
            chars[i] = caracteres[bytes[i] % caracteres.Length];
        }
        return new string(chars);
    }

    /// <summary>
    /// Panorama agregado de todas las empresas: cuántas hay en cada estado
    /// de membresía, ingreso mensual recurrente estimado de las activas
    /// (normalizando ciclos anuales a mensual), y cuántas llevan 30 días o
    /// más sin registrar una recogida (posible señal de riesgo de cancelación).
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardSoporteResponse>> Dashboard()
    {
        var empresas = await _context.Empresas.AsNoTracking().ToListAsync();
        var ahora = DateTime.UtcNow;

        var activas = empresas.Where(e => e.Activa).ToList();
        var suspendidas = empresas.Count(e => !e.Activa);
        var porVencer = activas.Count(e =>
            e.FechaFinMembresia >= ahora && e.FechaFinMembresia <= ahora.Add(VentanaPorVencer));
        var vencidas = activas.Count(e => e.FechaFinMembresia < ahora);
        var ingresoMensual = activas.Sum(EstimarMensual);

        // Recorre cada empresa impersonando su tenant para ver si tuvo
        // alguna recogida en los últimos 30 días. Es un request poco
        // frecuente (panel de soporte, no un endpoint de alto tráfico), así
        // que el costo de N consultas es aceptable frente a la utilidad de
        // detectar empresas inactivas.
        var limiteInactividad = ahora.AddDays(-30);
        var sinActividad = 0;
        foreach (var empresa in empresas)
        {
            _tenant.EmpresaId = empresa.Id;
            var tieneActividadReciente = await _context.Recogidas.AnyAsync(r => r.FechaCreacion >= limiteInactividad);
            if (!tieneActividadReciente)
            {
                sinActividad++;
            }
        }

        return Ok(new DashboardSoporteResponse(
            empresas.Count,
            activas.Count,
            suspendidas,
            porVencer,
            vencidas,
            ingresoMensual,
            sinActividad));
    }

    /// <summary>Normaliza el monto de membresía de una empresa a un equivalente mensual, según su ciclo de pago.</summary>
    private static decimal EstimarMensual(Empresa empresa)
    {
        if (empresa.MontoMembresia is null)
        {
            return 0m;
        }

        return empresa.CicloPago switch
        {
            "Anual" => empresa.MontoMembresia.Value / 12,
            "Único" => 0m,
            _ => empresa.MontoMembresia.Value,
        };
    }

    /// <summary>Exporta el listado de empresas a CSV (mismo patrón que <see cref="IngresosController.ExportCsv"/>).</summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportCsv()
    {
        var empresas = await _context.Empresas
            .AsNoTracking()
            .OrderBy(e => e.FechaFinMembresia)
            .ToListAsync();

        var sb = new StringBuilder();
        sb.AppendLine(
            "Id,NombreEmpresa,NombreContacto,TelefonoContacto,CorreoContacto,FechaInicioMembresia,FechaFinMembresia,MontoMembresia,CicloPago,Activa,EstadoMembresia,DiasParaVencimiento,UltimoRecordatorioEnviado,FechaCreacion");

        string Escape(string? valor)
        {
            valor ??= string.Empty;
            if (valor.Contains(',') || valor.Contains('"') || valor.Contains('\n') || valor.Contains('\r'))
            {
                return "\"" + valor.Replace("\"", "\"\"") + "\"";
            }
            return valor;
        }

        foreach (var empresa in empresas)
        {
            var r = ToResponse(empresa);
            sb.AppendLine(string.Join(",", new[]
            {
                r.Id.ToString(),
                Escape(r.NombreEmpresa),
                Escape(r.NombreContacto),
                Escape(r.TelefonoContacto),
                Escape(r.CorreoContacto),
                r.FechaInicioMembresia.ToString("o"),
                r.FechaFinMembresia.ToString("o"),
                r.MontoMembresia?.ToString("F2") ?? string.Empty,
                Escape(r.CicloPago),
                r.Activa.ToString(),
                r.EstadoMembresia,
                r.DiasParaVencimiento.ToString(),
                r.UltimoRecordatorioEnviado?.ToString("o") ?? string.Empty,
                r.FechaCreacion.ToString("o"),
            }));
        }

        var bytes = Encoding.UTF8.GetBytes(sb.ToString());
        var fileName = $"empresas_{DateTime.UtcNow:yyyyMMddHHmmss}.csv";
        return File(bytes, "text/csv; charset=utf-8", fileName);
    }

    /// <summary>Bitácora de soporte de una empresa: historial fechado e inmutable de interacciones (a diferencia del campo libre "Notas").</summary>
    [HttpGet("{id:int}/notas-soporte")]
    public async Task<ActionResult<List<NotaSoporteResponse>>> NotasDeEmpresa(int id)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var notas = await _context.NotasSoporte
            .AsNoTracking()
            .OrderByDescending(n => n.FechaCreacion)
            .Select(n => new NotaSoporteResponse(n.Id, n.Contenido, n.CreadoPorNombre, n.FechaCreacion))
            .ToListAsync();

        return Ok(notas);
    }

    /// <summary>Agrega una entrada a la bitácora de soporte de una empresa.</summary>
    [HttpPost("{id:int}/notas-soporte")]
    public async Task<ActionResult<NotaSoporteResponse>> CrearNotaSoporte(int id, CrearNotaSoporteRequest request)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        var nombreSoporte = User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Soporte";

        var nota = new NotaSoporte
        {
            Contenido = request.Contenido,
            CreadoPorUsuarioId = usuarioIdClaim,
            CreadoPorNombre = nombreSoporte,
        };
        _context.NotasSoporte.Add(nota);
        await _context.SaveChangesAsync();

        return CreatedAtAction(
            nameof(NotasDeEmpresa),
            new { id },
            new NotaSoporteResponse(nota.Id, nota.Contenido, nota.CreadoPorNombre, nota.FechaCreacion));
    }

    /// <summary>Clientes reales de una empresa (no solo el conteo), para que Soporte pueda ver/corregir un caso puntual sin pedirle capturas al cliente.</summary>
    [HttpGet("{id:int}/clientes")]
    public async Task<ActionResult<List<Cliente>>> ClientesDeEmpresa(int id, [FromQuery] string? busqueda)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var query = _context.Clientes
            .AsNoTracking()
            .OrderByDescending(c => c.FechaCreacion)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(busqueda))
        {
            query = query.Where(c => EF.Functions.ILike(c.Nombre, $"%{busqueda}%"));
        }

        var clientes = await query.Take(200).ToListAsync();
        return Ok(clientes);
    }

    /// <summary>Recogidas reales de una empresa (no solo el conteo), más recientes primero.</summary>
    [HttpGet("{id:int}/recogidas")]
    public async Task<ActionResult<List<RecogidaResponse>>> RecogidasDeEmpresa(int id, [FromQuery] string? busqueda)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var query = _context.Recogidas
            .AsNoTracking()
            .Include(r => r.Cliente)
            .Include(r => r.Usuario)
            .Include(r => r.Evidencias)
            .OrderByDescending(r => r.FechaCreacion)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(busqueda))
        {
            query = query.Where(r => r.Cliente != null && EF.Functions.ILike(r.Cliente.Nombre, $"%{busqueda}%"));
        }

        var recogidas = await query.Take(200).ToListAsync();

        return Ok(recogidas.Select(r => new RecogidaResponse(
            r.Id,
            r.ClienteId,
            r.Cliente?.Nombre,
            r.Cliente?.Telefono,
            r.UsuarioId,
            r.Usuario?.Nombre,
            r.Estado,
            r.CantidadPaquetes,
            r.Observaciones,
            r.Evidencias.Select(e => e.FotoUrl).ToList(),
            r.Latitud,
            r.Longitud,
            r.DineroRecibido,
            r.MontoCobrado,
            r.FechaCreacion,
            r.FechaProgramada,
            r.FechaRecogida)).ToList());
    }

    /// <summary>Ingresos reales de una empresa (no solo el conteo/total), más recientes primero.</summary>
    [HttpGet("{id:int}/ingresos")]
    public async Task<ActionResult<List<IngresoResponse>>> IngresosDeEmpresa(int id)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var ingresos = await _context.Ingresos
            .AsNoTracking()
            .Include(i => i.Cliente)
            .Include(i => i.ResponsableUsuario)
            .OrderByDescending(i => i.FechaIngreso)
            .Take(200)
            .Select(i => new IngresoResponse(
                i.Id,
                i.RecogidaId,
                i.ClienteId,
                i.Cliente != null ? i.Cliente.Nombre : string.Empty,
                i.ResponsableUsuarioId,
                i.ResponsableUsuario != null ? i.ResponsableUsuario.Nombre : string.Empty,
                i.Monto,
                i.FormaPago,
                i.FechaIngreso))
            .ToListAsync();

        return Ok(ingresos);
    }

    /// <summary>
    /// Encuentra a qué empresa pertenece un correo, para el caso en que un
    /// cliente escriba a Soporte dando solo su correo sin decir de qué
    /// empresa es. Busca en todas las empresas (IgnoreQueryFilters):
    /// exclusivo de Soporte, no hay impersonación de tenant involucrada.
    /// </summary>
    [HttpGet("buscar-usuario")]
    public async Task<ActionResult<BuscarUsuarioResponse>> BuscarUsuarioPorCorreo([FromQuery] string correo)
    {
        if (string.IsNullOrWhiteSpace(correo))
        {
            return BadRequest(new { mensaje = "Ingresa un correo" });
        }

        var usuario = await _context.Usuarios
            .IgnoreQueryFilters()
            .AsNoTracking()
            .Include(u => u.Role)
            .Include(u => u.Empresa)
            .FirstOrDefaultAsync(u => u.Correo == correo);

        if (usuario is null)
        {
            return NotFound(new { mensaje = "No se encontró ningún usuario con ese correo" });
        }

        return Ok(new BuscarUsuarioResponse(
            usuario.Id,
            usuario.Nombre,
            usuario.Correo,
            usuario.Rol,
            usuario.Activo,
            usuario.EmpresaId,
            usuario.Empresa?.NombreEmpresa));
    }

    /// <summary>
    /// Activa o desactiva el acceso de un usuario puntual (p. ej. un
    /// empleado que dejó la empresa), sin afectar al resto de usuarios de
    /// esa empresa — a diferencia de suspender la empresa completa.
    /// </summary>
    [HttpPut("{id:int}/usuarios/{usuarioId:int}/estado")]
    public async Task<IActionResult> CambiarEstadoUsuario(int id, int usuarioId, CambiarEstadoUsuarioRequest request)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        // Where(...).FirstOrDefaultAsync() en vez de FindAsync: así se
        // fuerza siempre una consulta nueva con el filtro de tenant recién
        // asignado, sin depender de si FindAsync resuelve desde el
        // change tracker (que podría no respetar el filtro si el usuario
        // ya estuviera trackeado de una consulta anterior en el mismo
        // request).
        var usuario = await _context.Usuarios.Where(u => u.Id == usuarioId).FirstOrDefaultAsync();
        if (usuario is null)
        {
            return NotFound(new { mensaje = "Usuario no existe en esta empresa" });
        }

        usuario.Activo = request.Activo;
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            usuario.Id,
            request.Activo ? "ACTIVAR_USUARIO_SOPORTE" : "DESACTIVAR_USUARIO_SOPORTE",
            null,
            new { usuario.Activo },
            $"Soporte {(request.Activo ? "activó" : "desactivó")} el acceso de {usuario.Nombre}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    /// <summary>Historial de pagos/renovaciones de membresía de una empresa.</summary>
    [HttpGet("{id:int}/pagos-membresia")]
    public async Task<ActionResult<List<PagoMembresiaResponse>>> PagosDeEmpresa(int id)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var pagos = await _context.PagosMembresia
            .AsNoTracking()
            .OrderByDescending(p => p.FechaPago)
            .Select(p => new PagoMembresiaResponse(
                p.Id, p.Monto, p.CicloPago, p.FechaPago, p.PeriodoDesde, p.PeriodoHasta, p.Notas, p.RegistradoPorNombre))
            .ToListAsync();

        return Ok(pagos);
    }

    /// <summary>Registra un nuevo pago/renovación de membresía para una empresa.</summary>
    [HttpPost("{id:int}/pagos-membresia")]
    public async Task<ActionResult<PagoMembresiaResponse>> CrearPagoMembresia(int id, CrearPagoMembresiaRequest request)
    {
        if (!await _context.Empresas.AnyAsync(e => e.Id == id))
        {
            return NotFound(new { mensaje = "Empresa no existe" });
        }

        _tenant.EmpresaId = id;

        var nombreSoporte = User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Soporte";

        var pago = new PagoMembresia
        {
            Monto = request.Monto,
            CicloPago = request.CicloPago,
            PeriodoDesde = request.PeriodoDesde,
            PeriodoHasta = request.PeriodoHasta,
            Notas = request.Notas,
            RegistradoPorNombre = nombreSoporte,
        };
        _context.PagosMembresia.Add(pago);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            id,
            "PAGO_MEMBRESIA",
            null,
            new { pago.Monto, pago.CicloPago, pago.PeriodoDesde, pago.PeriodoHasta },
            $"Soporte registró un pago de membresía de {pago.Monto:F2}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(
            nameof(PagosDeEmpresa),
            new { id },
            new PagoMembresiaResponse(pago.Id, pago.Monto, pago.CicloPago, pago.FechaPago, pago.PeriodoDesde, pago.PeriodoHasta, pago.Notas, pago.RegistradoPorNombre));
    }

    private static EmpresaResponse ToResponse(Empresa empresa)
    {
        var diasParaVencimiento = (int)Math.Ceiling((empresa.FechaFinMembresia - DateTime.UtcNow).TotalDays);
        var estado = !empresa.Activa
            ? "Suspendida"
            : diasParaVencimiento < 0
                ? "Vencida"
                : diasParaVencimiento <= VentanaPorVencer.TotalDays
                    ? "PorVencer"
                    : "Vigente";

        return new EmpresaResponse(
            empresa.Id,
            empresa.NombreEmpresa,
            empresa.NombreContacto,
            empresa.TelefonoContacto,
            empresa.CorreoContacto,
            empresa.FechaInicioMembresia,
            empresa.FechaFinMembresia,
            empresa.MontoMembresia,
            empresa.CicloPago,
            empresa.Notas,
            empresa.Activa,
            empresa.UltimoRecordatorioEnviado,
            empresa.FechaCreacion,
            estado,
            diasParaVencimiento);
    }
}
