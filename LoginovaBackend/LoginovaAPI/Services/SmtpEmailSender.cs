using System.Net;
using System.Net.Mail;

namespace LoginovaAPI.Services;

/// <summary>
/// Envia correos via SMTP usando la configuracion de la seccion "Smtp".
/// Si el host/usuario no estan configurados, registra el correo en el log
/// en vez de fallar, para no bloquear el flujo en entornos sin SMTP configurado.
/// </summary>
public class SmtpEmailSender : IEmailSender
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IConfiguration configuration, ILogger<SmtpEmailSender> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Envía el correo por SMTP. Si faltan credenciales SMTP en la configuración,
    /// no falla: solo deja constancia en el log y retorna, para que el flujo que
    /// lo invoca (p. ej. recuperación de contraseña) no se rompa en un entorno de
    /// desarrollo sin SMTP configurado. En producción (Render) esta implementación
    /// no se usa porque el proveedor bloquea el puerto SMTP saliente; ver
    /// <see cref="ResendEmailSender"/>.
    /// </summary>
    public async Task EnviarAsync(string destinatario, string asunto, string cuerpoTexto)
    {
        var host = _configuration["Smtp:Host"];
        var user = _configuration["Smtp:User"];
        var password = _configuration["Smtp:Password"];
        var from = _configuration["Smtp:From"];

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(user) || string.IsNullOrWhiteSpace(password))
        {
            _logger.LogWarning(
                "Smtp no esta configurado (Smtp:Host/Smtp:User/Smtp:Password). No se envio correo real a {Destinatario}. Asunto: {Asunto}",
                destinatario,
                asunto);
            return;
        }

        var port = int.TryParse(_configuration["Smtp:Port"], out var parsedPort) ? parsedPort : 587;
        var enableSsl = !bool.TryParse(_configuration["Smtp:EnableSsl"], out var parsedSsl) || parsedSsl;

        using var mensaje = new MailMessage
        {
            From = new MailAddress(string.IsNullOrWhiteSpace(from) ? user : from, "Loginova"),
            Subject = asunto,
            Body = cuerpoTexto,
            IsBodyHtml = false,
        };
        mensaje.To.Add(destinatario);

        using var cliente = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(user, password),
            EnableSsl = enableSsl,
        };

        await cliente.SendMailAsync(mensaje);
    }
}
