using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Representa una empresa que compró Loginova (no un cliente de recogidas:
/// esto es el CRM interno del vendedor para llevar control de a quién se le
/// vendió, con qué instalación cuenta y cuándo vence su membresía). Cada
/// empresa cliente corre su propia instalación independiente de Loginova
/// (modelo "una instalación por cliente"); este registro vive únicamente en
/// la instalación del vendedor, nunca en la de sus clientes.
/// </summary>
[Table("empresas_clientes")]
public class EmpresaCliente
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre_empresa")]
    public string NombreEmpresa { get; set; } = "";

    [Column("nombre_contacto")]
    public string? NombreContacto { get; set; }

    /// <summary>Teléfono del contacto, en formato internacional (ej. 573001234567) para el link de WhatsApp.</summary>
    [Column("telefono_contacto")]
    public string? TelefonoContacto { get; set; }

    [Column("correo_contacto")]
    public string? CorreoContacto { get; set; }

    /// <summary>URL base de la instalación de Loginova de esta empresa (su propio backend).</summary>
    [Column("url_instalacion")]
    public string? UrlInstalacion { get; set; }

    [Column("fecha_inicio_membresia")]
    public DateTime FechaInicioMembresia { get; set; }

    [Column("fecha_fin_membresia")]
    public DateTime FechaFinMembresia { get; set; }

    /// <summary>Monto que paga la empresa por su membresía (opcional, informativo).</summary>
    [Column("monto_membresia")]
    public decimal? MontoMembresia { get; set; }

    /// <summary>Ej. "Mensual", "Anual", "Único". Libre, no hay catálogo cerrado.</summary>
    [Column("ciclo_pago")]
    public string? CicloPago { get; set; }

    /// <summary>Notas de seguimiento del vendedor/soporte (no visibles para la empresa cliente).</summary>
    [Column("notas")]
    public string? Notas { get; set; }

    /// <summary>Falso cuando se da de baja definitiva a la empresa (no se elimina, para no perder el historial).</summary>
    [Column("activa")]
    public bool Activa { get; set; } = true;

    /// <summary>Última vez que se marcó como enviado un recordatorio manual (WhatsApp, llamada, etc.).</summary>
    [Column("ultimo_recordatorio_enviado")]
    public DateTime? UltimoRecordatorioEnviado { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
