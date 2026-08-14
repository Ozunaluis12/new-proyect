using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Una empresa cliente dentro del sistema multi-tenant: todos los datos de
/// negocio (usuarios, clientes de recogidas, recogidas, ingresos, etc.)
/// pertenecen a exactamente una Empresa, aislados de las demás por los
/// filtros de consulta globales configurados en
/// <see cref="Data.AppDbContext.OnModelCreating"/>. El rol "Soporte" (que no
/// pertenece a ninguna empresa) es quien crea, activa y suspende empresas
/// desde <c>EmpresasController</c>.
/// </summary>
[Table("empresas")]
public class Empresa
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

    /// <summary>
    /// Ciudad donde opera la empresa (ej. "Bucaramanga, Santander"). Junto con
    /// <see cref="LatitudOperacion"/>/<see cref="LongitudOperacion"/>, se usa
    /// como sesgo por defecto del buscador de direcciones de la app cuando el
    /// operador todavía no tiene GPS disponible, para que las sugerencias no
    /// aparezcan de otra ciudad. Configurable por Soporte al crear/editar la
    /// empresa; las coordenadas se resuelven geocodificando este texto desde
    /// la propia app (el backend no llama a ningún servicio de mapas).
    /// </summary>
    [Column("ciudad_operacion")]
    public string? CiudadOperacion { get; set; }

    [Column("latitud_operacion")]
    public double? LatitudOperacion { get; set; }

    [Column("longitud_operacion")]
    public double? LongitudOperacion { get; set; }

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

    /// <summary>Notas de seguimiento de Soporte (no visibles para la empresa).</summary>
    [Column("notas")]
    public string? Notas { get; set; }

    /// <summary>
    /// Si es falso, ningún usuario de esta empresa (admin, operadores, etc.)
    /// puede usar el sistema: el middleware de vigencia de membresía
    /// responde 402 en cada request. Soporte controla este campo desde
    /// "Activar"/"Suspender" en el Panel de Soporte.
    /// </summary>
    [Column("activa")]
    public bool Activa { get; set; } = true;

    /// <summary>Última vez que se marcó como enviado un recordatorio manual (WhatsApp, llamada, etc.).</summary>
    [Column("ultimo_recordatorio_enviado")]
    public DateTime? UltimoRecordatorioEnviado { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public List<Usuario> Usuarios { get; set; } = [];
}
