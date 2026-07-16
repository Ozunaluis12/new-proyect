using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa un cobro de dinero asociado a una recogida (efectivo o
/// transferencia). Se crea cuando un operador completa una recogida con
/// DineroRecibido = true. ResponsableUsuarioId siempre queda asignado a quien hizo
/// el cambio de estado que generó el cobro, no a quien creó la recogida ni a quien
/// estaba originalmente asignado: si el operador titular no pudo ir y otro completó
/// la recogida, el dinero queda a nombre de quien realmente la hizo.
/// </summary>
[Table("ingresos")]
public class Ingreso
{
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Recogida que generó este cobro.</summary>
    [Column("recogida_id")]
    public int RecogidaId { get; set; }

    public Recogida? Recogida { get; set; }

    [Column("cliente_id")]
    public int ClienteId { get; set; }

    public Cliente? Cliente { get; set; }

    /// <summary>
    /// Operador responsable de este dinero: quien realizó el cambio de estado que
    /// completó la recogida y cobró, no necesariamente quien la creó o a quien
    /// estaba asignada originalmente.
    /// </summary>
    [Column("responsable_usuario_id")]
    public int ResponsableUsuarioId { get; set; }

    public Usuario? ResponsableUsuario { get; set; }

    [Column("monto")]
    public decimal Monto { get; set; }

    /// <summary>Forma de pago del cobro: "Efectivo" o "Transferencia".</summary>
    [Column("forma_pago")]
    public string FormaPago { get; set; } = "Efectivo";

    [Column("fecha_ingreso")]
    public DateTime FechaIngreso { get; set; } = DateTime.UtcNow;

    /// <summary>Cierre de caja que recogió este ingreso. Null mientras esté pendiente.</summary>
    [Column("cierre_caja_id")]
    public int? CierreCajaId { get; set; }

    public CierreCaja? CierreCaja { get; set; }
}
