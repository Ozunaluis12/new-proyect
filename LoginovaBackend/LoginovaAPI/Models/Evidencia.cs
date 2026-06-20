using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa una evidencia (foto) de una recogida.
/// </summary>
[Table("evidencias")]
public class Evidencia
{
    /// <summary>Identificador unico de la evidencia.</summary>
    public int Id { get; set; }

    /// <summary>Identificador de la recogida asociada.</summary>
    [Column("recogida_id")]
    public int RecogidaId { get; set; }

    /// <summary>Relacion: recogida a la que pertenece esta evidencia.</summary>
    public Recogida? Recogida { get; set; }

    /// <summary>URL o ruta de la foto capturada como evidencia.</summary>
    [Column("url_foto")]
    public string FotoUrl { get; set; } = "";

    /// <summary>Comentario descriptivo o notas sobre la evidencia.</summary>
    [Column("comentario")]
    public string? Comentario { get; set; }

    /// <summary>Fecha y hora de creacion del registro de evidencia.</summary>
    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
