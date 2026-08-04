using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos para crear o actualizar una empresa cliente (CRM interno del vendedor).</summary>
public record EmpresaClienteRequest(
    [Required] string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    string? UrlInstalacion,
    [Required] DateTime FechaInicioMembresia,
    [Required] DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    bool Activa);

/// <summary>Datos de una empresa cliente devueltos por la API, con el estado de membresía ya calculado.</summary>
public record EmpresaClienteResponse(
    int Id,
    string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    string? UrlInstalacion,
    DateTime FechaInicioMembresia,
    DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    bool Activa,
    DateTime? UltimoRecordatorioEnviado,
    DateTime FechaCreacion,
    /// <summary>"Vencida", "PorVencer" (7 días o menos) o "Vigente". Ya calculado en el servidor para no repetir la regla en cada cliente.</summary>
    string EstadoMembresia,
    /// <summary>Días restantes hasta el vencimiento; negativo si ya venció.</summary>
    int DiasParaVencimiento);
