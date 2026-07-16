using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
/// <summary>
/// Controlador para gestionar las recogidas de clientes.
/// Proporciona operaciones CRUD y mapeo a DTOs de respuesta.
/// </summary>
public class RecogidasController : ControllerBase
{
    private static readonly HashSet<string> FormasPagoPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        "Efectivo",
        "Transferencia",
    };

    private static readonly HashSet<string> EstadosOperadorPermitidos = new(StringComparer.OrdinalIgnoreCase)
    {
        "Pendiente",
        "Recogida",
        "Cancelada",
    };

    private readonly AppDbContext _context;
    private readonly AuditoriaService _auditoria;
    private readonly EvidenciaStorageService _storageService;
    private readonly NotificacionService _notificacionService;
    private readonly PermisosService _permisosService;
    private readonly ILogger<RecogidasController> _logger;

    /// <summary>
    /// Constructor que recibe el contexto de datos y servicio de auditoría.
    /// </summary>
    public RecogidasController(
        AppDbContext context,
        AuditoriaService auditoria,
        EvidenciaStorageService storageService,
        NotificacionService notificacionService,
        PermisosService permisosService,
        ILogger<RecogidasController> logger)
    {
        _context = context;
        _auditoria = auditoria;
        _storageService = storageService;
        _notificacionService = notificacionService;
        _permisosService = permisosService;
        _logger = logger;
    }

    [HttpGet]
    /// <summary>
    /// Obtiene todas las recogidas con sus evidencias asociadas.
    /// </summary>
    public async Task<ActionResult<List<RecogidaResponse>>> GetAll()
    {
        var recogidas = await _context.Recogidas
            .AsNoTracking()
            .Include(recogida => recogida.Evidencias)
            .Include(recogida => recogida.Cliente)
            .Include(recogida => recogida.Usuario)
            .ToListAsync();

        return Ok(recogidas.Select(ToResponse).ToList());
    }

    [HttpGet("{id:int}")]
    /// <summary>
    /// Obtiene una recogida por su identificador, incluyendo evidencias.
    /// </summary>
    public async Task<ActionResult<RecogidaResponse>> GetById(int id)
    {
        var recogida = await _context.Recogidas
            .AsNoTracking()
            .Include(item => item.Evidencias)
            .Include(item => item.Cliente)
            .Include(item => item.Usuario)
            .SingleOrDefaultAsync(item => item.Id == id);

        return recogida is null ? NotFound() : Ok(ToResponse(recogida));
    }

    [HttpPost]
    /// <summary>
    /// Crea una nueva recogida y valida la existencia del cliente y usuario.
    /// </summary>
    public async Task<ActionResult<RecogidaResponse>> Create(RecogidaRequest request)
    {
        if (!await PuedeGestionarAsync(PermisosCatalogo.CrearRecogidas))
        {
            return Forbid();
        }

        if ((request.DineroRecibido || request.MontoCobrado.GetValueOrDefault() > 0m) &&
            !await PuedeGestionarAsync(PermisosCatalogo.RegistrarIngresos))
        {
            return Forbid();
        }

        var cliente = await _context.Clientes.FindAsync(request.ClienteId);
        if (cliente is null)
        {
            return BadRequest(new { mensaje = "Cliente no existe" });
        }

        var usuarioAsignado = request.UsuarioId.HasValue
            ? await _context.Usuarios.FindAsync(request.UsuarioId.Value)
            : null;
        if (usuarioAsignado is null)
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        var recogida = new Recogida
        {
            ClienteId = request.ClienteId,
            Cliente = cliente,
            UsuarioId = request.UsuarioId,
            Usuario = usuarioAsignado,
            Estado = string.IsNullOrWhiteSpace(request.Estado) ? "Pendiente" : request.Estado,
            CantidadPaquetes = request.CantidadPaquetes,
            Observaciones = request.Observaciones,
            Latitud = request.Latitud,
            Longitud = request.Longitud,
            DineroRecibido = request.DineroRecibido,
            MontoCobrado = request.MontoCobrado,
        };

        _context.Recogidas.Add(recogida);
        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Recogida",
            recogida.Id,
            "CREATE",
            null,
            new { recogida.ClienteId, recogida.UsuarioId, recogida.Estado, recogida.CantidadPaquetes, recogida.Observaciones, recogida.Latitud, recogida.Longitud, recogida.DineroRecibido, recogida.MontoCobrado },
            $"Nueva recogida creada para cliente #{recogida.ClienteId}",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        try
        {
            await _notificacionService.EnviarNotificacionAUsuariosOperativosAsync(
                "Nueva recogida creada",
                $"Se registró una nueva recogida #{recogida.Id} para el cliente #{recogida.ClienteId}.",
                "nueva_recogida",
                recogida.Id,
                new Dictionary<string, string>
                {
                    ["evento"] = "nueva_recogida",
                    ["clienteId"] = recogida.ClienteId.ToString(),
                },
                usuarioIdClaim > 0 ? usuarioIdClaim : null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "No se pudo notificar la creación de la recogida {RecogidaId}", recogida.Id);
        }

        return CreatedAtAction(nameof(GetById), new { id = recogida.Id }, ToResponse(recogida));
    }

    [HttpPut("{id:int}")]
    /// <summary>
    /// Actualiza los datos de una recogida existente.
    /// </summary>
    public async Task<IActionResult> Update(int id, RecogidaRequest request)
    {
        if (!await PuedeGestionarAsync(PermisosCatalogo.EditarRecogidas))
        {
            return Forbid();
        }

        if ((request.DineroRecibido || request.MontoCobrado.GetValueOrDefault() > 0m) &&
            !await PuedeGestionarAsync(PermisosCatalogo.RegistrarIngresos))
        {
            return Forbid();
        }

        var recogida = await _context.Recogidas.FindAsync(id);
        if (recogida is null)
        {
            return NotFound();
        }

        if (!await _context.Clientes.AnyAsync(c => c.Id == request.ClienteId))
        {
            return BadRequest(new { mensaje = "Cliente no existe" });
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        // Guardar valores anteriores para auditoría
        var valoresAnteriores = new
        {
            recogida.ClienteId,
            recogida.UsuarioId,
            recogida.Estado,
            recogida.CantidadPaquetes,
            recogida.Observaciones,
            recogida.Latitud,
            recogida.Longitud,
            recogida.DineroRecibido,
            recogida.MontoCobrado,
        };

        recogida.ClienteId = request.ClienteId;
        recogida.UsuarioId = request.UsuarioId;
        recogida.Estado = request.Estado;
        recogida.CantidadPaquetes = request.CantidadPaquetes;
        recogida.Observaciones = request.Observaciones;
        recogida.Latitud = request.Latitud;
        recogida.Longitud = request.Longitud;
        recogida.DineroRecibido = request.DineroRecibido;
        recogida.MontoCobrado = request.MontoCobrado;

        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Recogida",
            recogida.Id,
            "UPDATE",
            valoresAnteriores,
            new { recogida.ClienteId, recogida.UsuarioId, recogida.Estado, recogida.CantidadPaquetes, recogida.Observaciones, recogida.Latitud, recogida.Longitud, recogida.DineroRecibido, recogida.MontoCobrado },
            $"Recogida #{recogida.Id} actualizada",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        return NoContent();
    }

    [HttpPut("{id:int}/estado")]
    [RequestFormLimits(MultipartBodyLengthLimit = 10 * 1024 * 1024)]
    [RequestSizeLimit(10 * 1024 * 1024)]
    /// <summary>
    /// Actualiza solo el estado de una recogida y registra evidencia asociada.
    /// </summary>
    public async Task<ActionResult<RecogidaResponse>> UpdateEstado(int id, [FromForm] ActualizarEstadoRecogidaRequest request)
    {
        if (!await PuedeGestionarAsync(PermisosCatalogo.CambiarEstadoRecogidas))
        {
            return Forbid();
        }

        if (!EstadosOperadorPermitidos.Contains(request.Estado))
        {
            return BadRequest(new { mensaje = "Estado no permitido para el operador" });
        }

        if ((request.DineroRecibido || request.MontoCobrado.GetValueOrDefault() > 0m) &&
            !await PuedeGestionarAsync(PermisosCatalogo.RegistrarIngresos))
        {
            return Forbid();
        }

        if (request.DineroRecibido)
        {
            if (!string.Equals(request.Estado, "Recogida", StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new { mensaje = "Solo se puede registrar dinero al completar la recogida" });
            }

            if (request.MontoCobrado.GetValueOrDefault() <= 0m)
            {
                return BadRequest(new { mensaje = "Debes indicar un monto válido" });
            }

            if (string.IsNullOrWhiteSpace(request.FormaPago) || !FormasPagoPermitidas.Contains(request.FormaPago))
            {
                return BadRequest(new { mensaje = "La forma de pago debe ser Efectivo o Transferencia" });
            }
        }

        if ((!string.IsNullOrWhiteSpace(request.FotoUrl) || !string.IsNullOrWhiteSpace(request.Comentario)) &&
            !await PuedeGestionarAsync(PermisosCatalogo.SubirEvidencias))
        {
            return Forbid();
        }

        var recogida = await _context.Recogidas
            .Include(item => item.Evidencias)
            .SingleOrDefaultAsync(item => item.Id == id);

        if (recogida is null)
        {
            return NotFound();
        }

        var estadoAnterior = recogida.Estado;
        recogida.Estado = request.Estado;
        recogida.DineroRecibido = request.DineroRecibido;
        recogida.MontoCobrado = request.MontoCobrado;
        recogida.FormaPagoUltima = request.DineroRecibido ? request.FormaPago : null;

        if (request.CantidadPaquetes.HasValue)
        {
            recogida.CantidadPaquetes = request.CantidadPaquetes.Value;
        }

        if (string.Equals(request.Estado, "Recogida", StringComparison.OrdinalIgnoreCase))
        {
            recogida.FechaRecogida ??= DateTime.UtcNow;
        }

        string? fotoUrl = null;
        if (request.Foto is not null && request.Foto.Length > 0)
        {
            if (!_storageService.EsImagenValida(request.Foto, out var errorImagen))
            {
                return BadRequest(new { mensaje = errorImagen });
            }

            var fileName = _storageService.GenerarNombreArchivo(request.Foto);

            await using (var stream = request.Foto.OpenReadStream())
            {
                await _storageService.GuardarAsync(recogida.Id, fileName, stream, request.Foto.ContentType);
            }

            fotoUrl = _storageService.BuildPublicUrl(Request, _storageService.BuildRelativePath(recogida.Id, fileName));
        }
        else if (!string.IsNullOrWhiteSpace(request.FotoUrl))
        {
            fotoUrl = request.FotoUrl;
        }

        if (!string.IsNullOrWhiteSpace(fotoUrl))
        {
            _context.Evidencias.Add(new Evidencia
            {
                RecogidaId = recogida.Id,
                FotoUrl = fotoUrl,
                Comentario = request.Comentario ?? string.Empty,
            });
        }

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        _context.HistorialEstados.Add(new HistorialEstado
        {
            RecogidaId = recogida.Id,
            EstadoAnterior = estadoAnterior,
            EstadoNuevo = request.Estado,
            UsuarioId = usuarioIdClaim > 0 ? usuarioIdClaim : null,
        });

        if (request.DineroRecibido)
        {
            // El dinero se atribuye al operador ASIGNADO a la recogida (quien
            // físicamente tiene el efectivo/comprobante), no a quien haya
            // hecho la llamada a la API — de lo contrario, si un admin o
            // subadministrador marca el pago en nombre de un operador, el
            // dinero quedaría mal atribuido y la caja de ese operador nunca
            // lo mostraría como pendiente.
            var responsableId = recogida.UsuarioId ?? (usuarioIdClaim > 0 ? usuarioIdClaim : (int?)null);
            if (responsableId.HasValue)
            {
                _context.Ingresos.Add(new Ingreso
                {
                    RecogidaId = recogida.Id,
                    ClienteId = recogida.ClienteId,
                    ResponsableUsuarioId = responsableId.Value,
                    Monto = request.MontoCobrado ?? 0m,
                    FormaPago = request.FormaPago ?? "Efectivo",
                    FechaIngreso = DateTime.UtcNow,
                });
            }
        }

        await _context.SaveChangesAsync();

        // La recogida ya quedó guardada: un fallo al notificar no debe reportarse como
        // error al cliente ni ocultar que la operación principal sí tuvo éxito.
        try
        {
            if (request.DineroRecibido)
            {
                await _notificacionService.EnviarNotificacionAUsuariosConPermisoAsync(
                    PermisosCatalogo.VerIngresos,
                    "Dinero recibido",
                    $"Se registró dinero en la recogida #{recogida.Id} por un total de {request.MontoCobrado?.ToString("0.00") ?? "0.00"}.",
                    "dinero_recibido",
                    recogida.Id,
                    new Dictionary<string, string>
                    {
                        ["evento"] = "dinero_recibido",
                        ["monto"] = (request.MontoCobrado ?? 0m).ToString("0.00"),
                    },
                    usuarioIdClaim > 0 ? usuarioIdClaim : null);
            }

            await _notificacionService.EnviarNotificacionAUsuariosOperativosAsync(
                "Cambio de estado de recogida",
                $"La recogida #{recogida.Id} cambió a {request.Estado}.",
                "cambio_estado",
                recogida.Id,
                new Dictionary<string, string>
                {
                    ["evento"] = "cambio_estado",
                    ["estado"] = request.Estado,
                },
                usuarioIdClaim > 0 ? usuarioIdClaim : null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "No se pudieron enviar notificaciones para la recogida {RecogidaId}", recogida.Id);
        }

        var actualizada = await _context.Recogidas
            .AsNoTracking()
            .Include(item => item.Evidencias)
            .Include(item => item.Cliente)
            .Include(item => item.Usuario)
            .SingleAsync(item => item.Id == id);

        return Ok(ToResponse(actualizada));
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Administrador")]
    /// <summary>
    /// Elimina una recogida por su identificador.
    /// </summary>
    public async Task<IActionResult> Delete(int id)
    {
        var recogida = await _context.Recogidas.FindAsync(id);
        if (recogida is null)
        {
            return NotFound();
        }

        // Guardar valores para auditoría antes de eliminar
        var valoresEliminados = new
        {
            recogida.Id,
            recogida.ClienteId,
            recogida.UsuarioId,
            recogida.Estado,
            recogida.CantidadPaquetes,
            recogida.Observaciones,
        };

        _context.Recogidas.Remove(recogida);
        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Recogida",
            id,
            "DELETE",
            valoresEliminados,
            null,
            $"Recogida #{id} eliminada",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        return NoContent();
    }

    /// <summary>
    /// Convierte la entidad Recogida en un DTO de respuesta.
    /// </summary>
    private static RecogidaResponse ToResponse(Recogida recogida)
    {
        return new RecogidaResponse(
            recogida.Id,
            recogida.ClienteId,
            recogida.Cliente?.Nombre,
            recogida.Cliente?.Telefono,
            recogida.UsuarioId,
            recogida.Usuario?.Nombre,
            recogida.Estado,
            recogida.CantidadPaquetes,
            recogida.Observaciones,
            recogida.Evidencias.Select(evidencia => evidencia.FotoUrl).ToList(),
            recogida.Latitud,
            recogida.Longitud,
            recogida.DineroRecibido,
            recogida.MontoCobrado,
            recogida.FechaCreacion);
    }

    private async Task<bool> PuedeGestionarAsync(string permiso)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return false;
        }

        return await _permisosService.TienePermisoAsync(usuarioIdClaim, permiso);
    }
}
