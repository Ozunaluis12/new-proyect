using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa un cierre de caja: la operación de "cerrar" todos los ingresos
/// que un operador tiene pendientes (Ingreso.CierreCajaId == null) y agruparlos en un
/// registro con el desglose de efectivo/transferencia. No hay límite de un cierre por
/// día: puede existir un cierre manual (hecho por un admin) y luego el cierre automático
/// nocturno recogiendo lo que haya quedado pendiente después.
/// </summary>
[Table("cierres_caja")]
public class CierreCaja
{
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Operador al que pertenecen los ingresos incluidos en este cierre.</summary>
    [Column("operador_id")]
    public int OperadorId { get; set; }

    public Usuario? Operador { get; set; }

    [Column("fecha")]
    public DateTime Fecha { get; set; }

    /// <summary>Suma de MontoEfectivo + MontoTransferencia de todos los ingresos incluidos.</summary>
    [Column("monto_total")]
    public decimal MontoTotal { get; set; }

    /// <summary>Parte del monto total que corresponde a ingresos cobrados en efectivo.</summary>
    [Column("monto_efectivo")]
    public decimal MontoEfectivo { get; set; }

    /// <summary>Parte del monto total que corresponde a ingresos cobrados por transferencia.</summary>
    [Column("monto_transferencia")]
    public decimal MontoTransferencia { get; set; }

    [Column("observaciones")]
    public string? Observaciones { get; set; }

    /// <summary>Id del usuario (administrador) que generó el cierre manualmente. 0 cuando lo genera el cierre automático diario, en vez de un administrador.</summary>
    [Column("creado_por")]
    public int CreadoPor { get; set; }

    /// <summary>
    /// True cuando el cierre lo creó el cron automático de las 11:59pm hora Colombia
    /// (junto con CreadoPor == 0); false cuando lo generó manualmente un administrador.
    /// </summary>
    [Column("generado_automaticamente")]
    public bool GeneradoAutomaticamente { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    /// <summary>Relación: ingresos que quedaron agrupados dentro de este cierre.</summary>
    public List<Ingreso> Ingresos { get; set; } = [];
}
