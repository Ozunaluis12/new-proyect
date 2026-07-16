using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo central del negocio: representa la solicitud de un cliente para que le
/// recojan uno o más paquetes. Un operador procesa la recogida cambiando su Estado
/// (Pendiente → Recogida o Cancelada); ese cambio puede generar un Ingreso (cobro) y
/// Evidencias (fotos), y siempre queda registrado en HistorialEstados. UsuarioId se
/// reasigna SIEMPRE a quien hace el cambio de estado, no a quien la creó ni a quien
/// estaba asignada originalmente: si el operador asignado no pudo ir y otro la
/// completó, el control de la recogida queda a nombre de quien realmente la hizo.
/// </summary>
[Table("recogidas")]
public class Recogida
{
    [Column("id")]
    public int Id { get; set; }

    [Column("cliente_id")]
    public int ClienteId { get; set; }

    public Cliente? Cliente { get; set; }

    /// <summary>
    /// Operador actualmente responsable de la recogida. Se reasigna a quien hace
    /// cada cambio de estado (no necesariamente quien la creó o a quien se asignó
    /// originalmente). Nullable porque una recogida puede quedar sin operador
    /// asignado (por ejemplo recién creada).
    /// </summary>
    [Column("usuario_id")]
    public int? UsuarioId { get; set; }

    public Usuario? Usuario { get; set; }

    [Column("direccion_recogida")]
    public string DireccionRecogida { get; set; } = "";

    [Column("cantidad_paquetes")]
    public int CantidadPaquetes { get; set; }

    /// <summary>Indica si en algún momento se cobró dinero por esta recogida.</summary>
    [Column("dinero_recibido")]
    public bool DineroRecibido { get; set; }

    /// <summary>Monto cobrado más reciente. El detalle histórico de cada cobro vive en Ingresos.</summary>
    [Column("monto_cobrado")]
    public decimal? MontoCobrado { get; set; }

    /// <summary>Forma de pago ("Efectivo"/"Transferencia") del último cobro registrado en esta recogida.</summary>
    [Column("forma_pago_ultima")]
    public string? FormaPagoUltima { get; set; }

    [Column("observaciones")]
    public string? Observaciones { get; set; }

    /// <summary>Estado del flujo de la recogida: "Pendiente", "Recogida" o "Cancelada".</summary>
    [Column("estado")]
    public string Estado { get; set; } = "Pendiente";

    /// <summary>Fecha/hora en que el cliente pidió que se realizara la recogida.</summary>
    [Column("fecha_programada")]
    public DateTime? FechaProgramada { get; set; }

    /// <summary>Fecha/hora en que efectivamente se completó la recogida (estado pasó a "Recogida").</summary>
    [Column("fecha_recogida")]
    public DateTime? FechaRecogida { get; set; }

    [Column("latitud")]
    public decimal? Latitud { get; set; }

    [Column("longitud")]
    public decimal? Longitud { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    /// <summary>Relación: fotos de evidencia tomadas al procesar la recogida.</summary>
    public List<Evidencia> Evidencias { get; set; } = [];

    /// <summary>Relación: registro histórico de cada cambio de estado sufrido por esta recogida.</summary>
    public List<HistorialEstado> HistorialEstados { get; set; } = [];

    /// <summary>Relación: cobros de dinero generados a partir de esta recogida.</summary>
    public List<Ingreso> Ingresos { get; set; } = [];
}
