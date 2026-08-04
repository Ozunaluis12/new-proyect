using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que mantiene un registro historico de cambios de estado en las recogidas.
/// </summary>
[Table("historial_estados")]
public class HistorialEstado : ITenantOwned
{
    /// <summary>Identificador unico del registro historico.</summary>
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Empresa (tenant) a la que pertenece este registro. Ver <see cref="ITenantOwned"/>.</summary>
    [Column("empresa_id")]
    public int EmpresaId { get; set; }

    /// <summary>Identificador de la recogida cuyo estado cambio.</summary>
    [Column("recogida_id")]
    public int RecogidaId { get; set; }

    /// <summary>Relacion: recogida asociada a este cambio de estado.</summary>
    public Recogida? Recogida { get; set; }

    /// <summary>Estado anterior de la recogida.</summary>
    [Column("estado_anterior")]
    public string? EstadoAnterior { get; set; }

    /// <summary>Nuevo estado de la recogida.</summary>
    [Column("estado_nuevo")]
    public string? EstadoNuevo { get; set; }

    /// <summary>Identificador del usuario que realizo el cambio de estado.</summary>
    [Column("usuario_id")]
    public int? UsuarioId { get; set; }

    /// <summary>Relacion: usuario que realizo el cambio de estado.</summary>
    public Usuario? Usuario { get; set; }

    /// <summary>Fecha y hora en que ocurrio el cambio de estado.</summary>
    [Column("fecha_cambio")]
    public DateTime FechaCambio { get; set; } = DateTime.UtcNow;
}
