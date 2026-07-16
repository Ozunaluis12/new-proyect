using Microsoft.AspNetCore.Mvc.Filters;
using System.Text.Json;
using System.Text.Json.Nodes;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Http;

namespace LoginovaAPI.Services;

/// <summary>
/// Filtro de acción global que audita automáticamente cada request que modifica
/// datos (POST/PUT/PATCH/DELETE, nunca GET/HEAD). Captura quién hizo el cambio,
/// sobre qué entidad y con qué valores, y antes de guardar el log REDACTA los
/// campos sensibles (contraseñas, tokens) para que nunca queden en texto plano
/// en la auditoría. Se registra como filtro global en Program.cs, así que corre
/// en todos los controllers sin que cada uno tenga que invocarlo explícitamente.
/// </summary>
public class AuditoriaActionFilter : IAsyncActionFilter
{
    // Nombres de propiedad (o fragmentos) que nunca deben quedar en texto plano en el log de auditoría.
    private static readonly string[] CamposSensibles =
    {
        "password",
        "token",
        "secret",
        "fcmtoken",
    };

    private readonly AuditoriaService _auditoriaService;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditoriaActionFilter(AuditoriaService auditoriaService, IHttpContextAccessor httpContextAccessor)
    {
        _auditoriaService = auditoriaService;
        _httpContextAccessor = httpContextAccessor;
    }

    /// <summary>
    /// Se ejecuta alrededor de cada acción del controller. Antes de continuar
    /// con <paramref name="next"/>, identifica al usuario y la entidad afectada
    /// y serializa los argumentos de la acción (ya redactados) como "valores
    /// nuevos"; después de ejecutar la acción, persiste el registro de auditoría.
    /// Cualquier fallo al auditar se traga silenciosamente para no romper la
    /// respuesta real de la API por un problema del log.
    /// </summary>
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var http = _httpContextAccessor.HttpContext;
        var metodo = http?.Request?.Method ?? "";

        // Las lecturas (GET) no modifican nada: auditarlas solo genera ruido y escritura
        // en cada request. Solo se registran las acciones que cambian estado.
        if (string.Equals(metodo, "GET", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(metodo, "HEAD", StringComparison.OrdinalIgnoreCase))
        {
            await next();
            return;
        }

        var userId = int.TryParse(http?.User?.FindFirst("userId")?.Value, out var uid) ? uid : 0;

        var entidadTipo = context.ActionDescriptor.RouteValues.TryGetValue("controller", out var c) ? c ?? "" : "";
        int entidadId = 0;

        // Busca heurísticamente un id de entidad entre los argumentos de la acción:
        // primero un parámetro literal "id", si no hay, cualquiera que termine en "Id"
        // (p. ej. "recogidaId"). No requiere que cada acción declare explícitamente
        // cuál es su entidad.
        if (context.ActionArguments != null && context.ActionArguments.Count > 0)
        {
            foreach (var kv in context.ActionArguments)
            {
                if (kv.Key.Equals("id", StringComparison.OrdinalIgnoreCase) && int.TryParse(kv.Value?.ToString(), out var parsed))
                {
                    entidadId = parsed;
                    break;
                }

                if (kv.Key.EndsWith("Id", StringComparison.OrdinalIgnoreCase) && int.TryParse(kv.Value?.ToString(), out parsed))
                {
                    entidadId = parsed;
                    break;
                }
            }
        }

        string? valoresNuevos = null;
        try
        {
            // Serializa los argumentos de la acción (el body/params del request) y
            // redacta lo sensible ANTES de convertirlo a string: nunca se debe
            // materializar en memoria/log una contraseña o token en texto plano.
            var nodo = JsonSerializer.SerializeToNode(context.ActionArguments);
            RedactarSensibles(nodo);
            valoresNuevos = nodo?.ToJsonString();
        }
        catch { /* ignore serialization errors */ }

        // Ejecuta la acción real del controller antes de registrar el log, para
        // que la auditoría no agregue latencia perceptible a la respuesta.
        var executedContext = await next();

        // Arma descripción e IP de origen para el log
        var descripcion = $"{metodo} {http?.Request?.Path}";
        var ip = http?.Connection?.RemoteIpAddress?.ToString();

        try
        {
            await _auditoriaService.RegistrarCambio(userId, entidadTipo ?? string.Empty, entidadId, metodo, null, valoresNuevos, descripcion, ip);
        }
        catch
        {
            // Do not block the response if auditing fails
        }
    }

    /// <summary>
    /// Recorre el árbol JSON y reemplaza cualquier valor cuya propiedad coincida
    /// con un campo sensible (password, token, etc.) por un marcador fijo.
    /// </summary>
    private static void RedactarSensibles(JsonNode? nodo)
    {
        switch (nodo)
        {
            case JsonObject obj:
                foreach (var propiedad in obj.ToList())
                {
                    var esSensible = CamposSensibles.Any(campo =>
                        propiedad.Key.Contains(campo, StringComparison.OrdinalIgnoreCase));

                    if (esSensible)
                    {
                        obj[propiedad.Key] = "***REDACTED***";
                    }
                    else
                    {
                        RedactarSensibles(propiedad.Value);
                    }
                }
                break;
            case JsonArray array:
                foreach (var item in array)
                {
                    RedactarSensibles(item);
                }
                break;
        }
    }
}
