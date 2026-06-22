using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace LoginovaAPI.Services;

/// <summary>
/// Servicio para manejar notificaciones push y FCM tokens.
/// </summary>
public class NotificacionService
{
    private readonly AppDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    private const string FCMUrl = "https://fcm.googleapis.com/v1/projects/{0}/messages:send";

    public NotificacionService(AppDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
        _httpClient = new HttpClient();
    }

    /// <summary>
    /// Registra o actualiza el token FCM de un usuario.
    /// </summary>
    public async Task<bool> RegistrarFCMToken(int usuarioId, string fcmToken)
    {
        try
        {
            // Busca notificaciones previas de este usuario
            var notificacionExistente = await _context.Notificaciones
                .FirstOrDefaultAsync(n => n.UsuarioId == usuarioId && n.FcmToken == fcmToken);

            if (notificacionExistente != null)
            {
                return true; // Token ya registrado
            }

            // Crea un nuevo registro para el token
            var notificacion = new Notificacion
            {
                UsuarioId = usuarioId,
                FcmToken = fcmToken,
                Titulo = "Conexión establecida",
                Cuerpo = "Tu dispositivo está conectado a Loginova",
                Tipo = "general",
                FechaCreacion = DateTime.UtcNow
            };

            _context.Notificaciones.Add(notificacion);
            await _context.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error registrando FCM token: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Envía una notificación a un usuario específico.
    /// </summary>
    public async Task<bool> EnviarNotificacion(NotificacionRequest request)
    {
        try
        {
            var usuario = await _context.Usuarios.FindAsync(request.UsuarioId);
            if (usuario == null)
            {
                return false;
            }

            // Obtiene el token FCM más reciente del usuario
            var ultimaNotificacion = await _context.Notificaciones
                .Where(n => n.UsuarioId == request.UsuarioId)
                .OrderByDescending(n => n.FechaCreacion)
                .FirstOrDefaultAsync();

            if (ultimaNotificacion == null)
            {
                return false; // Usuario sin dispositivo registrado
            }

            // Crea el registro de notificación
            var notificacion = new Notificacion
            {
                UsuarioId = request.UsuarioId,
                FcmToken = ultimaNotificacion.FcmToken,
                Titulo = request.Titulo,
                Cuerpo = request.Cuerpo,
                Tipo = request.Tipo,
                RecogidaId = request.RecogidaId,
                DatosAdicionales = request.DatosAdicionales != null 
                    ? JsonSerializer.Serialize(request.DatosAdicionales) 
                    : null,
                FechaCreacion = DateTime.UtcNow
            };

            _context.Notificaciones.Add(notificacion);
            await _context.SaveChangesAsync();

            // Envía la notificación a través de FCM
            var enviado = await EnviarPorFCM(ultimaNotificacion.FcmToken, request);
            
            if (enviado)
            {
                notificacion.Enviado = true;
                notificacion.FechaEnvio = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return enviado;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error enviando notificación: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Envía notificación a múltiples usuarios.
    /// </summary>
    public async Task<int> EnviarNotificacionMasiva(
        List<int> usuarioIds, 
        string titulo, 
        string cuerpo, 
        string tipo = "general")
    {
        var enviadas = 0;

        foreach (var usuarioId in usuarioIds)
        {
            var request = new NotificacionRequest(usuarioId, titulo, cuerpo, tipo);
            if (await EnviarNotificacion(request))
            {
                enviadas++;
            }
        }

        return enviadas;
    }

    /// <summary>
    /// Envía la notificación real a través de Firebase Cloud Messaging.
    /// </summary>
    private async Task<bool> EnviarPorFCM(string fcmToken, NotificacionRequest request)
    {
        try
        {
            var projectId = _configuration["Firebase:ProjectId"];
            if (string.IsNullOrEmpty(projectId))
            {
                Console.WriteLine("Firebase ProjectId no configurado");
                return false;
            }

            var accessToken = await ObtenerAccessTokenFirebase();
            if (string.IsNullOrEmpty(accessToken))
            {
                return false;
            }

            var mensaje = new
            {
                message = new
                {
                    token = fcmToken,
                    notification = new
                    {
                        title = request.Titulo,
                        body = request.Cuerpo
                    },
                    data = new
                    {
                        tipo = request.Tipo,
                        recogidaId = request.RecogidaId?.ToString() ?? "",
                        timestamp = DateTime.UtcNow.ToString("O")
                    }
                }
            };

            var contenido = new StringContent(
                JsonSerializer.Serialize(mensaje),
                System.Text.Encoding.UTF8,
                "application/json");

            _httpClient.DefaultRequestHeaders.Authorization = 
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

            var response = await _httpClient.PostAsync(
                string.Format(FCMUrl, projectId),
                contenido);

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error en envío FCM: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Obtiene el access token para Firebase (desde archivo de configuración).
    /// NOTA: En producción, implementar OAuth2 properly.
    /// </summary>
    private async Task<string?> ObtenerAccessTokenFirebase()
    {
        try
        {
            // TODO: Implementar obtención real del access token
            // Por ahora, retorna null como placeholder
            return null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Obtiene todas las notificaciones de un usuario.
    /// </summary>
    public async Task<List<NotificacionResponse>> ObtenerNotificacionesUsuario(int usuarioId)
    {
        var notificaciones = await _context.Notificaciones
            .Where(n => n.UsuarioId == usuarioId)
            .OrderByDescending(n => n.FechaCreacion)
            .ToListAsync();

        return notificaciones.Select(ToResponse).ToList();
    }

    /// <summary>
    /// Marca una notificación como leída.
    /// </summary>
    public async Task<bool> MarcarComoLeida(int notificacionId)
    {
        var notificacion = await _context.Notificaciones.FindAsync(notificacionId);
        if (notificacion == null)
        {
            return false;
        }

        notificacion.Leido = true;
        notificacion.FechaLectura = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return true;
    }

    private static NotificacionResponse ToResponse(Notificacion n) => new(
        n.Id,
        n.UsuarioId,
        n.Titulo,
        n.Cuerpo,
        n.Tipo,
        n.Enviado,
        n.Leido,
        n.FechaCreacion,
        n.FechaEnvio,
        n.FechaLectura);
}
