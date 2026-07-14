using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record UsuarioResponse(
    int Id,
    string Nombre,
    string Correo,
    string Rol,
    List<string> Permisos);

public record UsuarioCreateRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    [Required, MinLength(8)] string Password,
    [Required] string Rol,
    List<string>? Permisos);

public record UsuarioUpdateRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    string? Password,
    [Required] string Rol,
    List<string>? Permisos);
