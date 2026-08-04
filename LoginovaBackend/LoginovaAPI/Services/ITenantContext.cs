using System.Security.Claims;

namespace LoginovaAPI.Services;

/// <summary>
/// Resuelve la empresa (tenant) del request actual. En requests normales se
/// lee del claim "empresaId" del JWT (null para el rol Soporte, que no
/// pertenece a ninguna empresa). El setter existe para el caso especial del
/// cron de cierre automático de caja (<see cref="Controllers.IngresosController.CierreAutomatico"/>),
/// que no tiene JWT/HttpContext.User y necesita "impersonar" cada empresa
/// por turno para reusar de forma segura la misma lógica ya filtrada por
/// tenant que usa un request normal.
/// </summary>
public interface ITenantContext
{
    int? EmpresaId { get; set; }
}

public class TenantContext : ITenantContext
{
    private int? _empresaIdOverride;
    private bool _resuelto;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public TenantContext(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? EmpresaId
    {
        get
        {
            if (_resuelto)
            {
                return _empresaIdOverride;
            }

            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("empresaId")?.Value;
            _empresaIdOverride = int.TryParse(claim, out var empresaId) ? empresaId : null;
            _resuelto = true;
            return _empresaIdOverride;
        }
        set
        {
            _empresaIdOverride = value;
            _resuelto = true;
        }
    }
}
