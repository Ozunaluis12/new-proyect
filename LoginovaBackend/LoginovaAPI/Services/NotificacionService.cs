using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Google.Apis.Auth.OAuth2;
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
    private const string FirebaseMessagingScope = "https://www.googleapis.com/auth/firebase.messaging";

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
        string tipo = "general",
        int? recogidaId = null,
        Dictionary<string, string>? datosAdicionales = null,
        int? excluirUsuarioId = null)
    {
        var enviadas = 0;

        foreach (var usuarioId in usuarioIds)
        {
            if (excluirUsuarioId.HasValue && usuarioId == excluirUsuarioId.Value)
            {
                continue;
            }

            var request = new NotificacionRequest(
                usuarioId,
                titulo,
                cuerpo,
                tipo,
                recogidaId,
                datosAdicionales);

            if (await EnviarNotificacion(request))
            {
                enviadas++;
            }
        }

        return enviadas;
    }

    /// <summary>
    /// Obtiene los ids de todos los usuarios con rol operativo (Administrador,
    /// Subadministrador u Operador), opcionalmente excluyendo a uno (típicamente
    /// quien disparó la acción, para no autonotificarse).
    /// </summary>
    public async Task<List<int>> ObtenerUsuariosOperativosAsync(int? excluirUsuarioId = null)
    {
        var usuarios = await _context.Usuarios
            .AsNoTracking()
            .Include(usuario => usuario.Role)
            .Where(usuario => usuario.Role != null &&
                (usuario.Role.Nombre == "Administrador" || usuario.Role.Nombre == "Subadministrador" || usuario.Role.Nombre == "Operador"))
            .Select(usuario => usuario.Id)
            .ToListAsync();

        if (excluirUsuarioId.HasValue)
        {
            usuarios = usuarios.Where(id => id != excluirUsuarioId.Value).ToList();
        }

        return usuarios;
    }

    /// <summary>
    /// Obtiene los ids de los usuarios que tienen un permiso específico
    /// (ver <see cref="PermisosCatalogo"/>), para notificar solo a quienes de
    /// verdad pueden actuar sobre el evento (p. ej. solo a quienes tienen
    /// VerIngresos cuando se registra un ingreso nuevo).
    /// </summary>
    public async Task<List<int>> ObtenerUsuariosConPermisoAsync(string permiso, int? excluirUsuarioId = null)
    {
        // Permisos es una propiedad calculada (deserializa PermisosJson en memoria) y no se
        // puede traducir a SQL: hay que materializar primero y filtrar del lado del cliente.
        var todosLosUsuarios = await _context.Usuarios.AsNoTracking().ToListAsync();

        var usuarios = todosLosUsuarios
            .Where(usuario => usuario.Permisos.Any(item => string.Equals(item, permiso, StringComparison.OrdinalIgnoreCase)))
            .Select(usuario => usuario.Id)
            .ToList();

        if (excluirUsuarioId.HasValue)
        {
            usuarios = usuarios.Where(id => id != excluirUsuarioId.Value).ToList();
        }

        return usuarios;
    }

    /// <summary>
    /// Atajo que combina <see cref="ObtenerUsuariosOperativosAsync"/> con
    /// <see cref="EnviarNotificacionMasiva"/> para notificar a todo el personal
    /// operativo en un solo llamado.
    /// </summary>
    public async Task<int> EnviarNotificacionAUsuariosOperativosAsync(
        string titulo,
        string cuerpo,
        string tipo,
        int? recogidaId = null,
        Dictionary<string, string>? datosAdicionales = null,
        int? excluirUsuarioId = null)
    {
        var usuarios = await ObtenerUsuariosOperativosAsync(excluirUsuarioId);
        return await EnviarNotificacionMasiva(
            usuarios,
            titulo,
            cuerpo,
            tipo,
            recogidaId,
            datosAdicionales,
            excluirUsuarioId);
    }

    /// <summary>
    /// Atajo que combina <see cref="ObtenerUsuariosConPermisoAsync"/> con
    /// <see cref="EnviarNotificacionMasiva"/> para notificar solo a los usuarios
    /// que tienen el permiso indicado.
    /// </summary>
    public async Task<int> EnviarNotificacionAUsuariosConPermisoAsync(
        string permiso,
        string titulo,
        string cuerpo,
        string tipo,
        int? recogidaId = null,
        Dictionary<string, string>? datosAdicionales = null,
        int? excluirUsuarioId = null)
    {
        var usuarios = await ObtenerUsuariosConPermisoAsync(permiso, excluirUsuarioId);
        return await EnviarNotificacionMasiva(
            usuarios,
            titulo,
            cuerpo,
            tipo,
            recogidaId,
            datosAdicionales,
            excluirUsuarioId);
    }

    /// <summary>
    /// Envía la notificación real a través de Firebase Cloud Messaging.
    /// </summary>
    private async Task<bool> EnviarPorFCM(string fcmToken, NotificacionRequest request)
    {
        try
        {
            var credential = ObtenerFirebaseCredential();
            if (credential == null)
            {
                Console.WriteLine("Firebase credential no configurada. Define Firebase:ServiceAccountPath, Firebase:ServiceAccountJson o GOOGLE_APPLICATION_CREDENTIALS.");
                return false;
            }

            var projectId = ObtenerFirebaseProjectId(credential);
            if (string.IsNullOrWhiteSpace(projectId))
            {
                Console.WriteLine("Firebase ProjectId no configurado. Define Firebase:ProjectId o usa una service account con project_id.");
                return false;
            }

            var accessToken = await ObtenerAccessTokenFirebase(credential);
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

            if (!response.IsSuccessStatusCode)
            {
                var detalle = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"FCM respondió {(int)response.StatusCode}: {detalle}");
            }

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error en envío FCM: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Obtiene el access token OAuth2 para Firebase Cloud Messaging.
    /// </summary>
    private static async Task<string?> ObtenerAccessTokenFirebase(GoogleCredential credential)
    {
        try
        {
            var scopedCredential = credential.IsCreateScopedRequired
                ? credential.CreateScoped(FirebaseMessagingScope)
                : credential;

            return await scopedCredential.UnderlyingCredential.GetAccessTokenForRequestAsync();
        }
        catch
        {
            return null;
        }
    }

    private GoogleCredential? ObtenerFirebaseCredential()
    {
        var serviceAccountJson = ObtenerServiceAccountJson();
        if (!string.IsNullOrWhiteSpace(serviceAccountJson))
        {
            return GoogleCredential.FromJson(serviceAccountJson);
        }

        return null;
    }

    private string? ObtenerFirebaseProjectId(GoogleCredential credential)
    {
        var configuredProjectId = _configuration["Firebase:ProjectId"];
        if (!string.IsNullOrWhiteSpace(configuredProjectId))
        {
            return configuredProjectId;
        }

        var serviceAccountJson = ObtenerServiceAccountJson();
        if (string.IsNullOrWhiteSpace(serviceAccountJson))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(serviceAccountJson);
            if (document.RootElement.TryGetProperty("project_id", out var projectId))
            {
                return projectId.GetString();
            }
        }
        catch (JsonException)
        {
            return null;
        }

        return null;
    }

    private string? ObtenerServiceAccountJson()
    {
        var serviceAccountJson = _configuration["Firebase:ServiceAccountJson"];
        if (!string.IsNullOrWhiteSpace(serviceAccountJson))
        {
            return serviceAccountJson;
        }

        var serviceAccountPath = _configuration["Firebase:ServiceAccountPath"];
        if (string.IsNullOrWhiteSpace(serviceAccountPath))
        {
            serviceAccountPath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
        }

        if (!string.IsNullOrWhiteSpace(serviceAccountPath) && File.Exists(serviceAccountPath))
        {
            return File.ReadAllText(serviceAccountPath);
        }

        return null;
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
    /// Marca una notificación como leída. Solo el dueño de la notificación puede hacerlo.
    /// </summary>
    public async Task<bool> MarcarComoLeida(int notificacionId, int usuarioId)
    {
        var notificacion = await _context.Notificaciones.FindAsync(notificacionId);
        if (notificacion == null || notificacion.UsuarioId != usuarioId)
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
