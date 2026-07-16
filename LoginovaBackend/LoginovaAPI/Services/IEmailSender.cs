namespace LoginovaAPI.Services;

/// <summary>
/// Abstracción para el envío de correos (usada principalmente en el flujo de
/// recuperación de contraseña). Tiene dos implementaciones: <see cref="SmtpEmailSender"/>
/// (SMTP tradicional, para desarrollo local) y <see cref="ResendEmailSender"/>
/// (API HTTP de Resend, usada en producción porque Render bloquea el puerto SMTP
/// saliente en su plan gratis). Program.cs decide cuál registrar en el contenedor
/// de DI según la configuración disponible.
/// </summary>
public interface IEmailSender
{
    /// <summary>Envía un correo de texto plano al destinatario indicado.</summary>
    Task EnviarAsync(string destinatario, string asunto, string cuerpoTexto);
}
