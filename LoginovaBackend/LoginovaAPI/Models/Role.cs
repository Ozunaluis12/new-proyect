using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace LoginovaAPI.Models;

/// <summary>
/// Catálogo de roles del sistema (Administrador, Subadministrador, Operador,
/// Cliente). El nombre del rol por sí solo no determina qué puede hacer un usuario:
/// eso lo define el conjunto de permisos granulares asignado en Usuario.PermisosJson,
/// que puede configurarse libremente sin importar el rol (salvo Administrador, que
/// siempre pasa cualquier chequeo de permiso sin necesidad de tenerlos listados).
/// </summary>
[Table("roles")]
public class Role
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre")]
    public string Nombre { get; set; } = "";

    [Column("descripcion")]
    public string? Descripcion { get; set; }

    /// <summary>Relación: usuarios que tienen asignado este rol.</summary>
    public List<Usuario> Usuarios { get; set; } = new List<Usuario>();
}
