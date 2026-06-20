using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace LoginovaAPI.Models;

[Table("roles")]
public class Role
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre")]
    public string Nombre { get; set; } = "";

    [Column("descripcion")]
    public string? Descripcion { get; set; }

    public List<Usuario> Usuarios { get; set; } = new List<Usuario>();
}
