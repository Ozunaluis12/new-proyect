using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa una ubicacion geografica de un usuario (operador).
/// </summary>
[Table("ubicaciones")]
public class Ubicacion
{
    /// <summary>Identificador unico del registro de ubicacion.</summary>
    public int Id { get; set; }

    /// <summary>Identificador del usuario (operador) que registra la ubicacion.</summary>
    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    /// <summary>Relacion: usuario asociado a esta ubicacion.</summary>
    public Usuario? Usuario { get; set; }

    /// <summary>Coordenada de latitud geografica.</summary>
    [Column("latitud")]
    public decimal Latitud { get; set; }

    /// <summary>Coordenada de longitud geografica.</summary>
    [Column("longitud")]
    public decimal Longitud { get; set; }

    /// <summary>Fecha y hora en que se registro la ubicacion.</summary>
    [Column("fecha_registro")]
    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;
}
