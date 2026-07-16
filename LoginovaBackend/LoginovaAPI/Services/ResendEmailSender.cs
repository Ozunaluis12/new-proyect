using System.Net.Http.Json;

namespace LoginovaAPI.Services;

/// <summary>
/// Envía correos vía la API HTTP de Resend (https://resend.com). A diferencia
/// de SMTP, viaja por el puerto 443, que ninguna plataforma bloquea — a
/// diferencia de SMTP (puerto 587/465), que Render y otros PaaS gratuitos sí
/// bloquean para evitar abuso.
/// </summary>
public class ResendEmailSender : IEmailSender
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ResendEmailSender> _logger;
    private readonly HttpClient _httpClient = new();

    public ResendEmailSender(IConfiguration configuration, ILogger<ResendEmailSender> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Envía el correo llamando a la API HTTP de Resend (POST /emails). Si Resend
    /// responde un código de error, se registra el detalle y se lanza una excepción
    /// para que el llamador (p. ej. el flujo de recuperación de contraseña) sepa
    /// que el envío falló en vez de asumir éxito silenciosamente.
    /// </summary>
    public async Task EnviarAsync(string destinatario, string asunto, string cuerpoTexto)
    {
        var apiKey = _configuration["Resend:ApiKey"];
        var from = _configuration["Resend:From"];
        if (string.IsNullOrWhiteSpace(from))
        {
            from = "Loginova <onboarding@resend.dev>";
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.resend.com/emails");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = JsonContent.Create(new
        {
            from,
            to = new[] { destinatario },
            subject = asunto,
            text = cuerpoTexto,
        });

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            _logger.LogError("Resend respondió {StatusCode}: {Body}", response.StatusCode, body);
            throw new InvalidOperationException($"Resend respondió {(int)response.StatusCode} al enviar el correo.");
        }
    }
}
