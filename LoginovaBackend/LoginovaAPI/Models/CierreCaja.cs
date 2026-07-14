using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

[Table("cierres_caja")]
public class CierreCaja
{
    [Column("id")]
    public int Id { get; set; }

    [Column("operador_id")]
    public int OperadorId { get; set; }

    public Usuario? Operador { get; set; }

    [Column("fecha")]
    public DateTime Fecha { get; set; }

    [Column("monto_total")]
    public decimal MontoTotal { get; set; }

    [Column("observaciones")]
    public string? Observaciones { get; set; }

    [Column("creado_por")]
    public int CreadoPor { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
