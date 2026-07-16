using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Controlador de ingresos (dinero cobrado en recogidas) y cierre de caja.
/// Un ingreso se crea automáticamente en <see cref="RecogidasController.UpdateEstado"/>
/// cuando se completa una recogida con cobro; este controlador expone su consulta,
/// exportación y el flujo de cierre de caja (manual y automático nocturno) que
/// agrupa los ingresos aún no cerrados de un operador en un <c>CierreCaja</c>.
/// </summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class IngresosController : ControllerBase
{
    // Colombia no observa horario de verano: el offset es fijo todo el año.
    private static readonly TimeSpan ZonaHorariaNegocio = TimeSpan.FromHours(-5);

    private readonly AppDbContext _context;
    private readonly PermisosService _permisosService;
    private readonly IConfiguration _configuration;

    public IngresosController(AppDbContext context, PermisosService permisosService, IConfiguration configuration)
    {
        _context = context;
        _permisosService = permisosService;
        _configuration = configuration;
    }

    /// <summary>
    /// Convierte una fecha de calendario (sin importar su Kind original) en el
    /// rango [inicio, fin) en UTC que corresponde a ese día completo en la
    /// zona horaria del negocio. Evita que ingresos registrados de noche
    /// (hora local) queden fuera del cierre de caja del día correcto.
    /// </summary>
    private static (DateTime DesdeUtc, DateTime HastaUtc) RangoDiaEnUtc(DateTime fecha)
    {
        var dia = fecha.Date;
        var desdeUtc = new DateTimeOffset(dia, ZonaHorariaNegocio).UtcDateTime;
        var hastaUtc = new DateTimeOffset(dia.AddDays(1), ZonaHorariaNegocio).UtcDateTime;
        return (desdeUtc, hastaUtc);
    }

    /// <summary>Fecha de calendario "de hoy" en la zona horaria del negocio.</summary>
    private static DateTime HoyNegocio()
    {
        // DateTimeOffset.Date siempre devuelve Kind=Unspecified, pero Npgsql
        // exige Kind=Utc para "timestamp with time zone". El valor ya está
        // calculado en la zona horaria correcta; solo falta marcarlo como Utc.
        var fechaLocal = DateTimeOffset.UtcNow.ToOffset(ZonaHorariaNegocio).Date;
        return DateTime.SpecifyKind(fechaLocal, DateTimeKind.Utc);
    }

    private async Task<int> UsuarioIdActualAsync()
    {
        return await Task.FromResult(int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0);
    }

    /// <summary>
    /// Lista los ingresos registrados, con filtros opcionales por cliente, operador
    /// responsable y rango de fechas (interpretado en la zona horaria del negocio).
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<IngresoResponse>>> GetAll(
        [FromQuery] string? cliente,
        [FromQuery] string? operador,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var query = _context.Set<Models.Ingreso>()
            .AsNoTracking()
            .Include(item => item.Cliente)
            .Include(item => item.ResponsableUsuario)
            .OrderByDescending(item => item.FechaIngreso)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(cliente))
        {
            query = query.Where(item => item.Cliente != null && EF.Functions.ILike(item.Cliente.Nombre, $"%{cliente}%"));
        }

        if (!string.IsNullOrWhiteSpace(operador))
        {
            query = query.Where(item => item.ResponsableUsuario != null && EF.Functions.ILike(item.ResponsableUsuario.Nombre, $"%{operador}%"));
        }

        if (fechaDesde.HasValue)
        {
            query = query.Where(item => item.FechaIngreso >= RangoDiaEnUtc(fechaDesde.Value).DesdeUtc);
        }

        if (fechaHasta.HasValue)
        {
            query = query.Where(item => item.FechaIngreso < RangoDiaEnUtc(fechaHasta.Value).HastaUtc);
        }

        var ingresos = await query
            .Select(item => new IngresoResponse(
                item.Id,
                item.RecogidaId,
                item.ClienteId,
                item.Cliente != null ? item.Cliente.Nombre : string.Empty,
                item.ResponsableUsuarioId,
                item.ResponsableUsuario != null ? item.ResponsableUsuario.Nombre : string.Empty,
                item.Monto,
                item.FormaPago,
                item.FechaIngreso))
            .ToListAsync();

        return Ok(ingresos);
    }

    /// <summary>
    /// Exporta a CSV los mismos ingresos que <see cref="GetAll"/>, con los mismos
    /// filtros, para que el administrador pueda auditar la caja fuera del sistema.
    /// </summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportCsv(
        [FromQuery] string? cliente,
        [FromQuery] string? operador,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var query = _context.Set<Models.Ingreso>()
            .AsNoTracking()
            .Include(item => item.Cliente)
            .Include(item => item.ResponsableUsuario)
            .OrderByDescending(item => item.FechaIngreso)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(cliente))
        {
            query = query.Where(item => item.Cliente != null && EF.Functions.ILike(item.Cliente.Nombre, $"%{cliente}%"));
        }

        if (!string.IsNullOrWhiteSpace(operador))
        {
            query = query.Where(item => item.ResponsableUsuario != null && EF.Functions.ILike(item.ResponsableUsuario.Nombre, $"%{operador}%"));
        }

        if (fechaDesde.HasValue)
        {
            query = query.Where(item => item.FechaIngreso >= RangoDiaEnUtc(fechaDesde.Value).DesdeUtc);
        }

        if (fechaHasta.HasValue)
        {
            query = query.Where(item => item.FechaIngreso < RangoDiaEnUtc(fechaHasta.Value).HastaUtc);
        }

        var ingresos = await query.ToListAsync();

        var sb = new StringBuilder();
        sb.AppendLine("Id,RecogidaId,ClienteId,Cliente,ResponsableUsuarioId,ResponsableUsuario,Monto,FormaPago,FechaIngreso");

        foreach (var item in ingresos)
        {
            string clienteNombre = item.Cliente != null ? item.Cliente.Nombre : string.Empty;
            string responsableNombre = item.ResponsableUsuario != null ? item.ResponsableUsuario.Nombre : string.Empty;
            string formaPago = item.FormaPago ?? string.Empty;
            string fecha = item.FechaIngreso.ToString("o");

            // Escapa comillas dobles y envuelve entre comillas los campos que
            // contengan comas o saltos de línea, para que el CSV no se desalinee
            // (p. ej. nombres de cliente u operador con comas).
            string Escape(string s)
            {
                if (s.Contains(",") || s.Contains("\"") || s.Contains("\n") || s.Contains("\r"))
                {
                    return "\"" + s.Replace("\"", "\"\"") + "\"";
                }
                return s;
            }

            sb.AppendLine(string.Join(",", new string[] {
                item.Id.ToString(),
                item.RecogidaId.ToString(),
                item.ClienteId.ToString(),
                Escape(clienteNombre),
                item.ResponsableUsuarioId.ToString(),
                Escape(responsableNombre),
                item.Monto.ToString("F2"),
                Escape(formaPago),
                Escape(fecha)
            }));
        }

        var bytes = Encoding.UTF8.GetBytes(sb.ToString());
        var fileName = $"ingresos_{DateTime.UtcNow:yyyyMMddHHmmss}.csv";
        return File(bytes, "text/csv; charset=utf-8", fileName);
    }

    /// <summary>Operadores y subadministradores que pueden tener caja (para el selector de cierre).</summary>
    [HttpGet("operadores")]
    public async Task<ActionResult<List<OperadorDisponibleResponse>>> OperadoresDisponibles()
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var operadores = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Role)
            .Where(u => u.Activo && u.Role != null && PermisosCatalogo.RolesGestion.Contains(u.Role.Nombre))
            .OrderBy(u => u.Nombre)
            .Select(u => new OperadorDisponibleResponse(u.Id, u.Nombre, u.Role!.Nombre))
            .ToListAsync();

        return Ok(operadores);
    }

    /// <summary>Dinero pendiente por cerrar de un operador: lo que aún no está en ningún cierre.</summary>
    [HttpGet("resumen-caja")]
    public async Task<ActionResult<ResumenCajaResponse>> ResumenCaja([FromQuery] int operadorId)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var operador = await _context.Usuarios.FindAsync(operadorId);
        if (operador is null)
        {
            return NotFound(new { mensaje = "Operador no existe" });
        }

        var pendientes = await _context.Set<Models.Ingreso>()
            .AsNoTracking()
            .Include(i => i.Cliente)
            .Where(i => i.ResponsableUsuarioId == operadorId && i.CierreCajaId == null)
            .OrderByDescending(i => i.FechaIngreso)
            .ToListAsync();

        var detalle = pendientes
            .Select(i => new IngresoDetalleResponse(
                i.Id,
                i.Cliente != null ? i.Cliente.Nombre : string.Empty,
                i.Monto,
                i.FormaPago,
                i.FechaIngreso))
            .ToList();

        var totalEfectivo = pendientes.Where(i => string.Equals(i.FormaPago, "Efectivo", StringComparison.OrdinalIgnoreCase)).Sum(i => i.Monto);
        var totalTransferencia = pendientes.Where(i => string.Equals(i.FormaPago, "Transferencia", StringComparison.OrdinalIgnoreCase)).Sum(i => i.Monto);

        return Ok(new ResumenCajaResponse(
            operadorId,
            operador.Nombre,
            totalEfectivo + totalTransferencia,
            totalEfectivo,
            totalTransferencia,
            pendientes.Count,
            detalle));
    }

    /// <summary>
    /// Cierra la caja de un operador: recoge todos sus ingresos aún no
    /// cerrados en un nuevo registro de cierre, con desglose por forma de pago.
    /// </summary>
    [HttpPost("cierre")]
    public async Task<ActionResult<CierreCajaResponse>> CerrarCaja([FromBody] CerrarCajaRequest request)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.CerrarCaja))
        {
            return Forbid();
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.OperadorId))
        {
            return BadRequest(new { mensaje = "Operador no existe" });
        }

        var cierre = await CerrarCajaOperadorAsync(request.OperadorId, usuarioIdClaim, automatico: false, request.Observaciones);
        if (cierre is null)
        {
            return BadRequest(new { mensaje = "Ese operador no tiene ingresos pendientes por cerrar" });
        }

        return Ok(cierre);
    }

    /// <summary>
    /// Disparado por un cron externo (GitHub Actions) a las 11:59pm hora de
    /// Colombia. Cierra automáticamente la caja de cualquier operador que
    /// tenga dinero pendiente, para que todos empiecen el día siguiente en
    /// ceros aunque el administrador haya olvidado cerrar manualmente.
    /// No usa JWT (no hay un usuario logueado en un cron): se valida con un
    /// secreto compartido en el header X-Cron-Secret.
    /// </summary>
    [HttpPost("cierre-automatico")]
    [AllowAnonymous]
    public async Task<IActionResult> CierreAutomatico([FromHeader(Name = "X-Cron-Secret")] string? secret)
    {
        var secretoEsperado = _configuration["CierreAutomatico:Secret"];
        if (string.IsNullOrWhiteSpace(secretoEsperado) || !string.Equals(secret, secretoEsperado, StringComparison.Ordinal))
        {
            return Unauthorized();
        }

        var operadoresConPendientes = await _context.Set<Models.Ingreso>()
            .Where(i => i.CierreCajaId == null)
            .Select(i => i.ResponsableUsuarioId)
            .Distinct()
            .ToListAsync();

        var cierres = new List<CierreCajaResponse>();
        foreach (var operadorId in operadoresConPendientes)
        {
            // creadoPor: 0 es el valor centinela para "sin usuario" (no hay un
            // admin logueado disparando esto, es el cron).
            var cierre = await CerrarCajaOperadorAsync(
                operadorId,
                creadoPor: 0,
                automatico: true,
                observaciones: "Cierre automático (11:59pm Colombia)");

            if (cierre is not null)
            {
                cierres.Add(cierre);
            }
        }

        return Ok(new { cierresGenerados = cierres.Count, cierres });
    }

    /// <summary>Historial de cierres de caja, con filtros opcionales.</summary>
    [HttpGet("cierres")]
    public async Task<ActionResult<List<CierreCajaResponse>>> HistorialCierres(
        [FromQuery] int? operadorId,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var query = _context.Set<Models.CierreCaja>()
            .AsNoTracking()
            .Include(c => c.Operador)
            .OrderByDescending(c => c.FechaCreacion)
            .AsQueryable();

        if (operadorId.HasValue)
        {
            query = query.Where(c => c.OperadorId == operadorId.Value);
        }

        // A diferencia de los filtros de ingresos (que usan RangoDiaEnUtc para
        // acotar por rango UTC), aquí se compara directo contra Fecha porque ese
        // campo ya guarda la fecha de calendario "de negocio" del cierre (ver
        // HoyNegocio), no un timestamp con hora.
        if (fechaDesde.HasValue)
        {
            query = query.Where(c => c.Fecha >= fechaDesde.Value.Date);
        }

        if (fechaHasta.HasValue)
        {
            query = query.Where(c => c.Fecha <= fechaHasta.Value.Date);
        }

        var cierres = await query
            .Select(c => new CierreCajaResponse(
                c.Id,
                c.OperadorId,
                c.Operador != null ? c.Operador.Nombre : string.Empty,
                c.Fecha,
                c.MontoTotal,
                c.MontoEfectivo,
                c.MontoTransferencia,
                c.Observaciones,
                c.GeneradoAutomaticamente,
                c.CreadoPor,
                c.FechaCreacion,
                null))
            .ToListAsync();

        return Ok(cierres);
    }

    /// <summary>Detalle de un cierre puntual, incluyendo los ingresos que recogió.</summary>
    [HttpGet("cierres/{id:int}")]
    public async Task<ActionResult<CierreCajaResponse>> DetalleCierre(int id)
    {
        var usuarioIdClaim = await UsuarioIdActualAsync();
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var cierre = await _context.Set<Models.CierreCaja>()
            .AsNoTracking()
            .Include(c => c.Operador)
            .Include(c => c.Ingresos)
            .ThenInclude(i => i.Cliente)
            .SingleOrDefaultAsync(c => c.Id == id);

        if (cierre is null)
        {
            return NotFound();
        }

        var detalle = cierre.Ingresos
            .OrderByDescending(i => i.FechaIngreso)
            .Select(i => new IngresoDetalleResponse(
                i.Id,
                i.Cliente != null ? i.Cliente.Nombre : string.Empty,
                i.Monto,
                i.FormaPago,
                i.FechaIngreso))
            .ToList();

        return Ok(new CierreCajaResponse(
            cierre.Id,
            cierre.OperadorId,
            cierre.Operador?.Nombre ?? string.Empty,
            cierre.Fecha,
            cierre.MontoTotal,
            cierre.MontoEfectivo,
            cierre.MontoTransferencia,
            cierre.Observaciones,
            cierre.GeneradoAutomaticamente,
            cierre.CreadoPor,
            cierre.FechaCreacion,
            detalle));
    }

    /// <summary>
    /// Recoge todos los ingresos aún no cerrados de un operador en un nuevo
    /// CierreCaja. Devuelve null si no había nada pendiente (no crea cierres
    /// vacíos), tanto para el cierre manual como para el automático.
    /// </summary>
    private async Task<CierreCajaResponse?> CerrarCajaOperadorAsync(
        int operadorId,
        int creadoPor,
        bool automatico,
        string? observaciones)
    {
        var pendientes = await _context.Set<Models.Ingreso>()
            .Where(i => i.ResponsableUsuarioId == operadorId && i.CierreCajaId == null)
            .ToListAsync();

        if (pendientes.Count == 0)
        {
            return null;
        }

        var totalEfectivo = pendientes.Where(i => string.Equals(i.FormaPago, "Efectivo", StringComparison.OrdinalIgnoreCase)).Sum(i => i.Monto);
        var totalTransferencia = pendientes.Where(i => string.Equals(i.FormaPago, "Transferencia", StringComparison.OrdinalIgnoreCase)).Sum(i => i.Monto);

        var cierre = new Models.CierreCaja
        {
            OperadorId = operadorId,
            Fecha = HoyNegocio(),
            MontoTotal = totalEfectivo + totalTransferencia,
            MontoEfectivo = totalEfectivo,
            MontoTransferencia = totalTransferencia,
            Observaciones = observaciones,
            CreadoPor = creadoPor,
            GeneradoAutomaticamente = automatico,
            FechaCreacion = DateTime.UtcNow,
        };

        foreach (var ingreso in pendientes)
        {
            ingreso.CierreCaja = cierre;
        }

        _context.Add(cierre);
        await _context.SaveChangesAsync();

        var operador = await _context.Usuarios.FindAsync(operadorId);

        return new CierreCajaResponse(
            cierre.Id,
            cierre.OperadorId,
            operador?.Nombre ?? string.Empty,
            cierre.Fecha,
            cierre.MontoTotal,
            cierre.MontoEfectivo,
            cierre.MontoTransferencia,
            cierre.Observaciones,
            cierre.GeneradoAutomaticamente,
            cierre.CreadoPor,
            cierre.FechaCreacion);
    }
}
