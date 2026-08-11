using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Un pago/renovación de membresía registrado para una empresa: a
/// diferencia de <see cref="Empresa.MontoMembresia"/> (solo el monto
/// vigente actual), cada fila aquí es un registro histórico e inmutable de
/// un cobro, para poder ver cuánto y cuándo pagó una empresa a lo largo
/// del tiempo. Implementa <see cref="ITenantOwned"/> como el resto de
/// tablas de negocio: Soporte "impersona" el tenant de la empresa para
/// crear/consultar, igual que con <see cref="NotaSoporte"/>.
/// </summary>
public class PagoMembresia : ITenantOwned
{
    [Column("id")]
    public int Id { get; set; }

    [Column("empresa_id")]
    public int EmpresaId { get; set; }

    [Column("monto")]
    public decimal Monto { get; set; }

    /// <summary>Ciclo de este pago puntual ("Mensual", "Anual", "Único"); puede diferir del ciclo actual de la empresa si cambió con el tiempo.</summary>
    [Column("ciclo_pago")]
    public string? CicloPago { get; set; }

    [Column("fecha_pago")]
    public DateTime FechaPago { get; set; } = DateTime.UtcNow;

    /// <summary>Periodo de membresía que cubre este pago (opcional, informativo).</summary>
    [Column("periodo_desde")]
    public DateTime? PeriodoDesde { get; set; }

    [Column("periodo_hasta")]
    public DateTime? PeriodoHasta { get; set; }

    [Column("notas")]
    public string? Notas { get; set; }

    /// <summary>Nombre de quien de Soporte registró el pago, copiado (no referenciado) para que sobreviva aunque esa cuenta cambie o se elimine.</summary>
    [Column("registrado_por_nombre")]
    public string RegistradoPorNombre { get; set; } = "";
}
