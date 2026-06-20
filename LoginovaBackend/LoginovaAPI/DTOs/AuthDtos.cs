using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record LoginRequest(
    [Required, EmailAddress] string Correo,
    [Required] string Password);

public record RegisterRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    [Required, MinLength(8)] string Password,
    string Rol);

public record ForgotPasswordRequest(
    [Required, EmailAddress] string Correo,
    [Required, MinLength(8)] string Password);

public record AuthResponse(
    string Token,
    UsuarioResponse Usuario);
