using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Catálogo de permisos granulares del sistema (ver también la clase estática
/// PermisosCatalogo). Cada Permiso es una capacidad independiente del nombre del rol:
/// se pueden asignar libremente a cualquier rol (ej. un Subadministrador puede tener
/// exactamente los mismos permisos que un Operador si el admin así lo configura).
/// La asignación real a un usuario vive serializada en Usuario.PermisosJson, no aquí
/// mediante una tabla intermedia; esta tabla funciona como catálogo/referencia de los
/// nombres válidos.
/// </summary>
[Table("permisos")]
public class Permiso
{
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Nombre único del permiso, usado como valor dentro de Usuario.PermisosJson.</summary>
    [Column("nombre")]
    public string Nombre { get; set; } = string.Empty;

    [Column("descripcion")]
    public string? Descripcion { get; set; }
}
