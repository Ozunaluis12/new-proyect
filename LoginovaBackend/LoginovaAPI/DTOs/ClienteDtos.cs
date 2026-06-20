using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record ClienteRequest(
    [Required] string Nombre,
    [Required] string Telefono,
    [Required] string Direccion,
    [Required] string Ciudad);
