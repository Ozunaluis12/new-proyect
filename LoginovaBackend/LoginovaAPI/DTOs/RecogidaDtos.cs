using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos para crear o actualizar una recogida (uso administrativo, no el flujo de cambio de estado del operador).</summary>
public record RecogidaRequest(
    [Required] int ClienteId,
    int? UsuarioId,
    [Required] string Estado,
    [Range(0, int.MaxValue)] int CantidadPaquetes,
    string? Observaciones,
    decimal? Latitud,
    decimal? Longitud,
    bool DineroRecibido,
    decimal? MontoCobrado,
    /// <summary>Horario límite acordado con el cliente para completar la recogida. Opcional.</summary>
    DateTime? FechaProgramada);

/// <summary>
/// Datos que envía el operador al procesar una recogida (Pendiente → Recogida o
/// Cancelada). Este es el flujo que dispara la reasignación de UsuarioId e
/// Ingreso.ResponsableUsuarioId a quien hace la llamada, y opcionalmente adjunta
/// evidencia fotográfica y el cobro de dinero.
/// </summary>
public class ActualizarEstadoRecogidaRequest
{
    [Required]
    public string Estado { get; set; } = string.Empty;

    /// <summary>
    /// Cantidad real de paquetes, contada por el operador al recoger. Es
    /// opcional porque no todos los cambios de estado implican un conteo
    /// (por ejemplo, cancelar no requiere actualizarla).
    /// </summary>
    [Range(0, int.MaxValue)]
    public int? CantidadPaquetes { get; set; }

    /// <summary>URL de una foto de evidencia ya subida (alternativa a enviar el archivo en Foto).</summary>
    public string? FotoUrl { get; set; }

    public string? Comentario { get; set; }

    /// <summary>Indica si en este cambio de estado se cobró dinero al cliente.</summary>
    public bool DineroRecibido { get; set; }

    public decimal? MontoCobrado { get; set; }

    /// <summary>Forma de pago del cobro: "Efectivo" o "Transferencia".</summary>
    public string? FormaPago { get; set; }

    /// <summary>Archivo de foto de evidencia enviado directamente (multipart/form-data), alternativa a FotoUrl.</summary>
    public IFormFile? Foto { get; set; }
}

/// <summary>Datos de una recogida devueltos por la API, con los nombres de cliente/usuario ya resueltos en vez de solo IDs.</summary>
public record RecogidaResponse(
    int Id,
    int ClienteId,
    string? ClienteNombre,
    string? ClienteTelefono,
    int? UsuarioId,
    string? UsuarioNombre,
    string Estado,
    int CantidadPaquetes,
    string? Observaciones,
    List<string> Evidencias,
    decimal? Latitud,
    decimal? Longitud,
    bool DineroRecibido,
    decimal? MontoCobrado,
    DateTime? FechaCreacion,
    /// <summary>Horario límite acordado con el cliente. Null si no se fijó uno.</summary>
    DateTime? FechaProgramada,
    /// <summary>Fecha/hora en que efectivamente se completó (estado pasó a "Recogida"). Null mientras siga pendiente.</summary>
    DateTime? FechaRecogida);
