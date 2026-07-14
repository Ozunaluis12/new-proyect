using Microsoft.AspNetCore.Mvc.Filters;
using System.Text.Json;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Http;

namespace LoginovaAPI.Services;

public class AuditoriaActionFilter : IAsyncActionFilter
{
    private readonly AuditoriaService _auditoriaService;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditoriaActionFilter(AuditoriaService auditoriaService, IHttpContextAccessor httpContextAccessor)
    {
        _auditoriaService = auditoriaService;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var http = _httpContextAccessor.HttpContext;
        var userId = int.TryParse(http?.User?.FindFirst("userId")?.Value, out var uid) ? uid : 0;

        var entidadTipo = context.ActionDescriptor.RouteValues.TryGetValue("controller", out var c) ? c ?? "" : "";
        int entidadId = 0;

        // Try to find an id in action arguments
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
            valoresNuevos = JsonSerializer.Serialize(context.ActionArguments);
        }
        catch { /* ignore serialization errors */ }

        // Execute action
        var executedContext = await next();

        // Build description and IP
        var descripcion = $"{http?.Request?.Method} {http?.Request?.Path}";
        var ip = http?.Connection?.RemoteIpAddress?.ToString();

        try
        {
            await _auditoriaService.RegistrarCambio(userId, entidadTipo ?? string.Empty, entidadId, http?.Request?.Method ?? "", null, valoresNuevos, descripcion, ip);
        }
        catch
        {
            // Do not block the response if auditing fails
        }
    }
}
