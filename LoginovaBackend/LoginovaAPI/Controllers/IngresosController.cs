using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class IngresosController : ControllerBase
{
    // Colombia no observa horario de verano: el offset es fijo todo el año.
    private static readonly TimeSpan ZonaHorariaNegocio = TimeSpan.FromHours(-5);

    private readonly AppDbContext _context;
    private readonly PermisosService _permisosService;

    public IngresosController(AppDbContext context, PermisosService permisosService)
    {
        _context = context;
        _permisosService = permisosService;
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

    [HttpGet]
    public async Task<ActionResult<List<IngresoResponse>>> GetAll(
        [FromQuery] string? cliente,
        [FromQuery] string? operador,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
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

    [HttpGet("export")]
    public async Task<IActionResult> ExportCsv(
        [FromQuery] string? cliente,
        [FromQuery] string? operador,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
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

            // Escape double quotes and wrap fields containing commas in quotes
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

    public record CierreCajaRequest(int OperadorId, DateTime Fecha, string? Observaciones);

    [HttpGet("resumen-caja")]
    public async Task<ActionResult<object>> ResumenCaja(
        [FromQuery] int operadorId,
        [FromQuery] DateTime? fecha)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var date = fecha?.Date ?? DateTime.UtcNow.Date;
        var (desdeUtc, hastaUtc) = RangoDiaEnUtc(date);

        var ingresosQuery = _context.Set<Models.Ingreso>()
            .AsNoTracking()
            .Where(i => i.ResponsableUsuarioId == operadorId && i.FechaIngreso >= desdeUtc && i.FechaIngreso < hastaUtc);

        var total = await ingresosQuery.SumAsync(i => (decimal?)i.Monto) ?? 0m;
        var count = await ingresosQuery.CountAsync();

        return Ok(new { OperadorId = operadorId, Fecha = date, Total = total, Count = count });
    }

    [HttpPost("cierre")]
    public async Task<IActionResult> CerrarCaja([FromBody] CierreCajaRequest request)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.VerIngresos))
        {
            return Forbid();
        }

        var date = request.Fecha.Date;

        var yaExiste = await _context.Set<Models.CierreCaja>()
            .AnyAsync(c => c.OperadorId == request.OperadorId && c.Fecha == date);
        if (yaExiste)
        {
            return Conflict(new { mensaje = "La caja de ese operador ya fue cerrada para esa fecha" });
        }

        var (desdeUtc, hastaUtc) = RangoDiaEnUtc(date);

        var ingresos = await _context.Set<Models.Ingreso>()
            .Where(i => i.ResponsableUsuarioId == request.OperadorId && i.FechaIngreso >= desdeUtc && i.FechaIngreso < hastaUtc)
            .ToListAsync();

        var montoTotal = ingresos.Sum(i => i.Monto);

        var cierre = new Models.CierreCaja
        {
            OperadorId = request.OperadorId,
            Fecha = date,
            MontoTotal = montoTotal,
            Observaciones = request.Observaciones,
            CreadoPor = usuarioIdClaim,
            FechaCreacion = DateTime.UtcNow
        };

        _context.Add(cierre);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            var yaExisteAhora = await _context.Set<Models.CierreCaja>()
                .AnyAsync(c => c.OperadorId == request.OperadorId && c.Fecha == date);
            if (yaExisteAhora)
            {
                // Otra petición concurrente ganó la carrera y ya cerró esta caja.
                return Conflict(new { mensaje = "La caja de ese operador ya fue cerrada para esa fecha" });
            }

            throw;
        }

        return Ok(cierre);
    }
}
