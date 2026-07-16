using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos para crear o actualizar un Cliente (empresa o persona que solicita recogidas).</summary>
public record ClienteRequest(
    [Required] string Nombre,
    [Required] string Telefono,
    [Required] string Direccion,
    [Required] string Ciudad);
