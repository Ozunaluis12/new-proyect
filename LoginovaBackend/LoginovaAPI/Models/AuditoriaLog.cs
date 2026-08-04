namespace LoginovaAPI.Models;

using System.ComponentModel.DataAnnotations.Schema;

/// <summary>
/// Modelo que representa un registro de auditoría de cambios en el sistema.
/// Registra quién, qué, cuándo y cómo cambió una entidad.
/// </summary>
public class AuditoriaLog
{
    /// <summary>
    /// Identificador único del registro de auditoría.
    /// </summary>
    [Column("id")]
    public int Id { get; set; }

    /// <summary>
    /// Empresa (tenant) a la que pertenece este registro. Nullable (no
    /// implementa <see cref="ITenantOwned"/>, igual que <see cref="Usuario"/>)
    /// porque las acciones de Soporte (crear/activar/suspender empresas) no
    /// pertenecen a ninguna empresa y aun así deben poder auditarse.
    /// </summary>
    [Column("empresa_id")]
    public int? EmpresaId { get; set; }

    /// <summary>
    /// ID del usuario que realizó el cambio.
    /// </summary>
    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    /// <summary>
    /// Tipo de entidad que fue modificada (ej: Recogida, Usuario, Cliente).
    /// </summary>
    [Column("entidad_tipo")]
    public string EntidadTipo { get; set; } = string.Empty;

    /// <summary>
    /// ID de la entidad que fue modificada.
    /// </summary>
    [Column("entidad_id")]
    public int EntidadId { get; set; }

    /// <summary>
    /// Acción realizada: CREATE, UPDATE, DELETE.
    /// </summary>
    [Column("accion")]
    public string Accion { get; set; } = string.Empty;

    /// <summary>
    /// Valores antiguos en formato JSON (para UPDATE/DELETE).
    /// </summary>
    [Column("valores_anteriores")]
    public string? ValoresAnteriores { get; set; }

    /// <summary>
    /// Valores nuevos en formato JSON (para CREATE/UPDATE).
    /// </summary>
    [Column("valores_nuevos")]
    public string? ValoresNuevos { get; set; }

    /// <summary>
    /// Descripción legible del cambio.
    /// </summary>
    [Column("descripcion")]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Fecha y hora en que se realizó el cambio.
    /// </summary>
    [Column("fecha_cambio")]
    public DateTime FechaCambio { get; set; }

    /// <summary>
    /// Dirección IP del cliente que realizó la solicitud.
    /// </summary>
    [Column("ip_address")]
    public string? IpAddress { get; set; }
}
