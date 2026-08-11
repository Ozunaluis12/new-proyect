using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Configuración global (una sola fila, Id=1) del propio equipo de
/// Soporte — no pertenece a ninguna empresa. Hoy solo guarda las
/// plantillas de mensaje de WhatsApp para el recordatorio de vencimiento,
/// para que Soporte pueda ajustar el texto sin tocar código.
/// </summary>
public class ConfiguracionSoporte
{
    [Column("id")]
    public int Id { get; set; }

    [Column("plantilla_recordatorio_vigente")]
    public string PlantillaRecordatorioVigente { get; set; } = "";

    [Column("plantilla_recordatorio_vencida")]
    public string PlantillaRecordatorioVencida { get; set; } = "";
}
