using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Controlador que gestiona las notificaciones push y FCM tokens.
/// </summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class NotificacionesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly NotificacionService _notificacionService;

    public NotificacionesController(AppDbContext context, NotificacionService notificacionService)
    {
        _context = context;
        _notificacionService = notificacionService;
    }

    /// <summary>
    /// Registra el token FCM de un usuario en su dispositivo.
    /// </summary>
    [HttpPost("token")]
    public async Task<IActionResult> RegistrarToken([FromBody] FCMTokenRequest request)
    {
        var usuarioIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (usuarioIdClaim == null || !int.TryParse(usuarioIdClaim.Value, out var usuarioId))
        {
            return Unauthorized(new { mensaje = "Usuario no identificado" });
        }

        var resultado = await _notificacionService.RegistrarFCMToken(usuarioId, request.FcmToken);
        return resultado ? Ok(new { mensaje = "Token registrado" }) : BadRequest();
    }

    /// <summary>
    /// Envía una notificación a un usuario específico.
    /// </summary>
    [HttpPost("enviar")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> EnviarNotificacion([FromBody] NotificacionRequest request)
    {
        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        var resultado = await _notificacionService.EnviarNotificacion(request);
        return resultado 
            ? Ok(new { mensaje = "Notificación enviada" }) 
            : BadRequest(new { mensaje = "Error al enviar notificación" });
    }

    /// <summary>
    /// Obtiene todas las notificaciones del usuario autenticado.
    /// </summary>
    [HttpGet("mis-notificaciones")]
    public async Task<ActionResult<List<NotificacionResponse>>> ObtenerMisNotificaciones()
    {
        var usuarioIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (usuarioIdClaim == null || !int.TryParse(usuarioIdClaim.Value, out var usuarioId))
        {
            return Unauthorized();
        }

        var notificaciones = await _notificacionService.ObtenerNotificacionesUsuario(usuarioId);
        return Ok(notificaciones);
    }

    /// <summary>
    /// Marca una notificación como leída.
    /// </summary>
    [HttpPut("{id:int}/marcar-leida")]
    public async Task<IActionResult> MarcarComoLeida(int id)
    {
        var resultado = await _notificacionService.MarcarComoLeida(id);
        return resultado ? NoContent() : NotFound();
    }

    /// <summary>
    /// Endpoint de prueba para verificar que las notificaciones funcionan.
    /// </summary>
    [HttpPost("test")]
    public async Task<IActionResult> EnviarNotificacionPrueba()
    {
        var usuarioIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (usuarioIdClaim == null || !int.TryParse(usuarioIdClaim.Value, out var usuarioId))
        {
            return Unauthorized();
        }

        var request = new NotificacionRequest(
            usuarioId,
            "Notificación de Prueba",
            "Esta es una notificación de prueba desde Loginova",
            "general");

        var resultado = await _notificacionService.EnviarNotificacion(request);
        return resultado 
            ? Ok(new { mensaje = "Notificación de prueba enviada" }) 
            : BadRequest();
    }
}
