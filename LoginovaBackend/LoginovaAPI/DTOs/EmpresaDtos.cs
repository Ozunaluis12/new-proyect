using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos para crear una empresa nueva junto con su primer Administrador.</summary>
public record CrearEmpresaRequest(
    [Required] string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    [Required] DateTime FechaInicioMembresia,
    [Required] DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    [Required] string AdminNombre,
    [Required, EmailAddress] string AdminCorreo,
    [Required, MinLength(8)] string AdminPassword);

/// <summary>Datos para actualizar una empresa existente (no toca su administrador).</summary>
public record ActualizarEmpresaRequest(
    [Required] string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    [Required] DateTime FechaInicioMembresia,
    [Required] DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas);

/// <summary>Datos de una empresa devueltos por la API, con el estado de membresía ya calculado.</summary>
public record EmpresaResponse(
    int Id,
    string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    DateTime FechaInicioMembresia,
    DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    bool Activa,
    DateTime? UltimoRecordatorioEnviado,
    DateTime FechaCreacion,
    /// <summary>"Suspendida" (Activa=false), "Vencida", "PorVencer" (7 días o menos) o "Vigente".</summary>
    string EstadoMembresia,
    /// <summary>Días restantes hasta el vencimiento; negativo si ya venció.</summary>
    int DiasParaVencimiento);
