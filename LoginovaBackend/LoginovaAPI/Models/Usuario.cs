using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;
using System.Text.Json;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa a cualquier persona que inicia sesión en el sistema:
/// Administrador, Subadministrador u Operador (los Clientes del negocio son un
/// modelo aparte, ver Cliente.cs, y no inician sesión). El rol asignado (RoleId)
/// determina el nombre visible, pero el control fino de qué puede hacer cada
/// Usuario lo da el conjunto de permisos guardado en PermisosJson: se puede
/// configurar cualquier combinación de permisos independientemente del rol (ej. un
/// Subadministrador puede tener exactamente los mismos permisos que un Operador).
/// El rol "Administrador" siempre pasa cualquier chequeo de permiso sin importar
/// PermisosJson (bypass total, ver PermisosCatalogo).
/// </summary>
[Table("usuarios")]
public class Usuario
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre")]
    public string Nombre { get; set; } = "";

    [Column("correo")]
    public string Correo { get; set; } = "";

    /// <summary>
    /// Hash de la contraseña (nunca la contraseña en claro). Marcado con
    /// [JsonIgnore] para que jamás se serialice y termine expuesto en una
    /// respuesta de la API; los DTOs de respuesta (ej. UsuarioResponse) tampoco
    /// incluyen este campo.
    /// </summary>
    [Column("password_hash")]
    [System.Text.Json.Serialization.JsonIgnore]
    public string Password { get; set; } = "";

    [Column("telefono")]
    public string? Telefono { get; set; }

    [Column("rol_id")]
    public int RoleId { get; set; }

    public Role? Role { get; set; }

    /// <summary>Atajo de solo lectura (no mapeado a columna) con el nombre del rol asociado.</summary>
    [NotMapped]
    public string Rol => Role?.Nombre ?? string.Empty;

    /// <summary>
    /// Lista de nombres de permisos asignados a este usuario, serializada como
    /// arreglo JSON en la base de datos (no hay tabla intermedia usuario-permiso).
    /// Se deserializa mediante la propiedad calculada Permisos y se actualiza con
    /// EstablecerPermisos.
    /// </summary>
    [Column("permisos_json")]
    public string PermisosJson { get; set; } = "[]";

    /// <summary>Propiedad calculada (no mapeada) que deserializa PermisosJson a una lista utilizable en código.</summary>
    [NotMapped]
    public List<string> Permisos => string.IsNullOrWhiteSpace(PermisosJson)
        ? []
        : JsonSerializer.Deserialize<List<string>>(PermisosJson) ?? [];

    /// <summary>
    /// Normaliza (recorta espacios, descarta vacíos, elimina duplicados sin
    /// distinguir mayúsculas/minúsculas) y guarda la lista de permisos en
    /// PermisosJson.
    /// </summary>
    public void EstablecerPermisos(IEnumerable<string> permisos)
    {
        PermisosJson = JsonSerializer.Serialize(
            permisos
                .Select(permiso => permiso.Trim())
                .Where(permiso => !string.IsNullOrWhiteSpace(permiso))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList());
    }

    /// <summary>Si es false, el usuario no debería poder iniciar sesión (baja lógica, no se borra el registro).</summary>
    [Column("activo")]
    public bool Activo { get; set; } = true;

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    /// <summary>Relación: recogidas actualmente asignadas a este usuario (como operador).</summary>
    public List<Recogida> Recogidas { get; set; } = new List<Recogida>();

    /// <summary>Relación: historial de ubicaciones geográficas reportadas por este usuario (operador).</summary>
    public List<Ubicacion> Ubicaciones { get; set; } = new List<Ubicacion>();

    /// <summary>Relación: cambios de estado de recogidas realizados por este usuario.</summary>
    public List<HistorialEstado> HistorialEstados { get; set; } = new List<HistorialEstado>();

    /// <summary>Relación: ingresos (cobros) cuyo responsable es este usuario.</summary>
    public List<Ingreso> IngresosRecibidos { get; set; } = new List<Ingreso>();

    /// <summary>Relación: cierres de caja generados sobre los ingresos de este usuario.</summary>
    public List<CierreCaja> CierresCaja { get; set; } = new List<CierreCaja>();
}
