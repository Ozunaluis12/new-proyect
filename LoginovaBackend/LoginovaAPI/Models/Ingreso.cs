using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

[Table("ingresos")]
public class Ingreso
{
    [Column("id")]
    public int Id { get; set; }

    [Column("recogida_id")]
    public int RecogidaId { get; set; }

    public Recogida? Recogida { get; set; }

    [Column("cliente_id")]
    public int ClienteId { get; set; }

    public Cliente? Cliente { get; set; }

    [Column("responsable_usuario_id")]
    public int ResponsableUsuarioId { get; set; }

    public Usuario? ResponsableUsuario { get; set; }

    [Column("monto")]
    public decimal Monto { get; set; }

    [Column("forma_pago")]
    public string FormaPago { get; set; } = "Efectivo";

    [Column("fecha_ingreso")]
    public DateTime FechaIngreso { get; set; } = DateTime.UtcNow;

    /// <summary>Cierre de caja que recogió este ingreso. Null mientras esté pendiente.</summary>
    [Column("cierre_caja_id")]
    public int? CierreCajaId { get; set; }

    public CierreCaja? CierreCaja { get; set; }
}
