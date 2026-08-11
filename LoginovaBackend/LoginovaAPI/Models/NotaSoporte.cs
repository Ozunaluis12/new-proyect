using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Bitácora de soporte para una empresa: a diferencia del campo libre
/// <see cref="Empresa.Notas"/> (una sola nota editable, sin historial),
/// cada fila aquí es un registro fechado e inmutable de una interacción de
/// soporte, para que quede memoria de qué pasó y quién lo atendió aunque
/// haya varias personas en el equipo de Soporte con el tiempo. Implementa
/// <see cref="ITenantOwned"/> como el resto de tablas de negocio: Soporte
/// "impersona" el tenant de la empresa (mismo mecanismo que usa para ver
/// usuarios/auditoría) y el filtro de consulta + la red de seguridad de
/// SaveChangesAsync hacen el resto, sin código especial para esta tabla.
/// </summary>
public class NotaSoporte : ITenantOwned
{
    [Column("id")]
    public int Id { get; set; }

    [Column("empresa_id")]
    public int EmpresaId { get; set; }

    [Column("contenido")]
    public string Contenido { get; set; } = "";

    /// <summary>Id del usuario Soporte que escribió la nota (sin FK: si esa cuenta se borra, la nota debe conservarse).</summary>
    [Column("creado_por_usuario_id")]
    public int CreadoPorUsuarioId { get; set; }

    /// <summary>Nombre del autor al momento de escribir la nota (copiado, no referenciado, para que sobreviva aunque la cuenta cambie de nombre o se elimine).</summary>
    [Column("creado_por_nombre")]
    public string CreadoPorNombre { get; set; } = "";

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
