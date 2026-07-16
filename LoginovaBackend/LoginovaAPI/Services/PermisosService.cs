using LoginovaAPI.Data;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Services;

/// <summary>
/// Catálogo central de todos los permisos granulares que puede tener un
/// usuario (aparte del rol "Administrador", que siempre tiene acceso total).
/// Estas constantes son los valores que se guardan en <c>Usuario.PermisosJson</c>
/// y las mismas que se siembran como filas en la tabla Permisos (ver
/// <see cref="LoginovaAPI.Data.AppDbContext.OnModelCreating"/>) para que se
/// puedan listar/asignar desde la administración.
/// </summary>
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
    public const string CerrarCaja = "cerrar_caja";

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
        CerrarCaja,
    };

    /// <summary>
    /// Roles que pueden manejar caja/ingresos (además del Administrador, que
    /// siempre puede todo). Se usa para filtrar a quién tiene sentido asignarle
    /// permisos de caja o mostrarle en pantallas de gestión de ingresos.
    /// </summary>
    public static readonly HashSet<string> RolesGestion = new(StringComparer.OrdinalIgnoreCase)
    {
        "Operador",
        "Subadministrador",
    };
}

/// <summary>
/// Punto central de autorización granular del sistema. Todo endpoint que
/// necesite validar un permiso específico (más allá de `[Authorize]` por rol)
/// pasa por <see cref="TienePermisoAsync"/>.
/// </summary>
public class PermisosService
{
    private readonly AppDbContext _context;

    public PermisosService(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Determina si el usuario puede realizar una acción protegida por
    /// <paramref name="permiso"/>. El rol "Administrador" siempre pasa (bypass
    /// total, sin importar su lista de permisos); cualquier otro rol necesita
    /// tener el permiso explícito en <c>Usuario.Permisos</c> (deserializado de
    /// PermisosJson). Un usuario inexistente nunca tiene permiso.
    /// </summary>
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

    /// <summary>
    /// Limpia una lista de permisos recibida del cliente: recorta espacios,
    /// descarta vacíos y elimina duplicados (comparación sin distinguir
    /// mayúsculas). Se usa antes de guardar los permisos de un usuario para
    /// no persistir basura en PermisosJson.
    /// </summary>
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

    /// <summary>
    /// Valida que cada permiso de la lista exista en <see cref="PermisosCatalogo.Todos"/>,
    /// para evitar que se guarde en un usuario un permiso inventado o mal escrito.
    /// Una lista nula se considera válida (equivale a "sin permisos").
    /// </summary>
    public static bool SonPermisosValidos(IEnumerable<string>? permisos)
    {
        if (permisos is null)
        {
            return true;
        }

        return permisos.All(permiso => PermisosCatalogo.Todos.Contains(permiso));
    }
}