using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos enviados por el cliente para iniciar sesión.</summary>
public record LoginRequest(
    [Required, EmailAddress] string Correo,
    [Required] string Password);

/// <summary>Solicita el envío del código de 6 dígitos de recuperación de contraseña al correo indicado.</summary>
public record ForgotPasswordRequest(
    [Required, EmailAddress] string Correo);

/// <summary>
/// Confirma el cambio de contraseña usando el código de 6 dígitos recibido por
/// correo (Token). El código se valida contra el hash guardado en
/// PasswordResetToken, no contra un valor en claro.
/// </summary>
public record ResetPasswordRequest(
    [Required, EmailAddress] string Correo,
    [Required] string Token,
    [Required, MinLength(8)] string NuevaPassword);

/// <summary>Respuesta de un login/registro exitoso: el JWT de sesión y los datos públicos del usuario.</summary>
public record AuthResponse(
    string Token,
    UsuarioResponse Usuario);
