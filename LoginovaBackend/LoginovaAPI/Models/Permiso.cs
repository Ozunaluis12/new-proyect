using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

[Table("permisos")]
public class Permiso
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre")]
    public string Nombre { get; set; } = string.Empty;

    [Column("descripcion")]
    public string? Descripcion { get; set; }
}
