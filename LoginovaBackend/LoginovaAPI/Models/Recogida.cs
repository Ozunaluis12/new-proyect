using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

[Table("recogidas")]
public class Recogida
{
    public int Id { get; set; }

    [Column("cliente_id")]
    public int ClienteId { get; set; }

    public Cliente? Cliente { get; set; }

    [Column("usuario_id")]
    public int? UsuarioId { get; set; }

    public Usuario? Usuario { get; set; }

    [Column("direccion_recogida")]
    public string DireccionRecogida { get; set; } = "";

    [Column("cantidad_paquetes")]
    public int CantidadPaquetes { get; set; }

    [Column("observaciones")]
    public string? Observaciones { get; set; }

    [Column("estado")]
    public string Estado { get; set; } = "Pendiente";

    [Column("fecha_programada")]
    public DateTime? FechaProgramada { get; set; }

    [Column("fecha_recogida")]
    public DateTime? FechaRecogida { get; set; }

    [Column("latitud")]
    public decimal? Latitud { get; set; }

    [Column("longitud")]
    public decimal? Longitud { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public List<Evidencia> Evidencias { get; set; } = [];
    public List<HistorialEstado> HistorialEstados { get; set; } = [];
}
