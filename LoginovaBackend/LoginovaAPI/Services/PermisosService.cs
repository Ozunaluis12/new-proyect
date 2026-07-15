using LoginovaAPI.Data;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Services;

public static class PermisosCatalogo
{
    public const string CrearRecogidas = "crear_recogidas";
    public const string EditarRecogidas = "editar_recogidas";
    public const string CambiarEstadoRecogidas = "cambiar_estado_recogidas";
    public const string SubirEvidencias = "subir_evidencias";
    public const string RegistrarIngresos = "registrar_ingresos";
    public const string VerIngresos = "ver_ingresos";
    public const string VerUsuarios = "ver_usuarios";
    public const string GestionarUsuarios = "gestionar_usuarios";
    public const string VerAuditoria = "ver_auditoria";
    public const string GestionarNotificaciones = "gestionar_notificaciones";
    public const string VerUbicaciones = "ver_ubicaciones";
    public const string GestionarUbicaciones = "gestionar_ubicaciones";
    public const string VerClientes = "ver_clientes";
    public const string GestionarClientes = "gestionar_clientes";

    public static readonly HashSet<string> Todos = new(StringComparer.OrdinalIgnoreCase)
    {
        CrearRecogidas,
        EditarRecogidas,
        CambiarEstadoRecogidas,
        SubirEvidencias,
        RegistrarIngresos,
        VerIngresos,
        VerUsuarios,
        GestionarUsuarios,
        VerAuditoria,
        GestionarNotificaciones,
        VerUbicaciones,
        GestionarUbicaciones,
        VerClientes,
        GestionarClientes,
    };

    public static readonly HashSet<string> RolesGestion = new(StringComparer.OrdinalIgnoreCase)
    {
        "Operador",
        "Subadministrador",
    };
}

public class PermisosService
{
    private readonly AppDbContext _context;

    public PermisosService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<bool> TienePermisoAsync(int usuarioId, string permiso)
    {
        var usuario = await _context.Usuarios
            .AsNoTracking()
            .Include(item => item.Role)
            .SingleOrDefaultAsync(item => item.Id == usuarioId);

        if (usuario is null)
        {
            return false;
        }

        if (string.Equals(usuario.Rol, "Administrador", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return usuario.Permisos.Any(item => string.Equals(item, permiso, StringComparison.OrdinalIgnoreCase));
    }

    public static List<string> NormalizarPermisos(IEnumerable<string>? permisos)
    {
        if (permisos is null)
        {
            return [];
        }

        return permisos
            .Select(permiso => permiso?.Trim() ?? string.Empty)
            .Where(permiso => !string.IsNullOrWhiteSpace(permiso))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    public static bool SonPermisosValidos(IEnumerable<string>? permisos)
    {
        if (permisos is null)
        {
            return true;
        }

        return permisos.All(permiso => PermisosCatalogo.Todos.Contains(permiso));
    }
}