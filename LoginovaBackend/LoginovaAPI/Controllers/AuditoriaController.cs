using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Controlador de solo lectura para consultar el registro de auditoría (quién
/// cambió qué, cuándo y desde qué IP). Los logs los genera automáticamente
/// <c>AuditoriaActionFilter</c> en cada creación/edición/borrado relevante (con
/// campos sensibles como password o token ya redactados antes de guardarse), por
/// lo que aquí no hay endpoints de escritura. Restringido a Administrador porque
/// expone actividad de todos los usuarios del sistema.
/// </summary>
[ApiController]
[Authorize(Roles = "Administrador")]
[Route("api/[controller]")]
public class AuditoriaController : ControllerBase
{
    private readonly AuditoriaService _auditoriaService;

    public AuditoriaController(AuditoriaService auditoriaService)
    {
        _auditoriaService = auditoriaService;
    }

    /// <summary>
    /// Obtiene todos los registros de auditoría (solo admin).
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<AuditoriaLog>>> GetAll()
    {
        var logs = await _auditoriaService
            .ObtenerLogs()
            .Take(100) // Limitar a últimos 100 registros
            .ToListAsync();

        return Ok(logs);
    }

    /// <summary>
    /// Obtiene registros de auditoría para una entidad específica.
    /// </summary>
    [HttpGet("entidad/{entidadTipo}/{entidadId:int}")]
    public async Task<ActionResult<List<AuditoriaLog>>> GetByEntidad(string entidadTipo, int entidadId)
    {
        var logs = await _auditoriaService
            .ObtenerLogsPorEntidad(entidadTipo, entidadId)
            .Take(50)
            .ToListAsync();

        return Ok(logs);
    }

    /// <summary>
    /// Obtiene registros de auditoría para un usuario específico.
    /// </summary>
    [HttpGet("usuario/{usuarioId:int}")]
    public async Task<ActionResult<List<AuditoriaLog>>> GetByUsuario(int usuarioId)
    {
        var logs = await _auditoriaService
            .ObtenerLogsPorUsuario(usuarioId)
            .Take(50)
            .ToListAsync();

        return Ok(logs);
    }

    /// <summary>
    /// Obtiene registros de auditoría filtrados por tipo de acción.
    /// </summary>
    [HttpGet("accion/{accion}")]
    public async Task<ActionResult<List<AuditoriaLog>>> GetByAccion(string accion)
    {
        var logsValidos = new[] { "CREATE", "UPDATE", "DELETE" };
        if (!logsValidos.Contains(accion.ToUpper()))
        {
            return BadRequest(new { mensaje = $"Acción inválida. Debe ser: {string.Join(", ", logsValidos)}" });
        }

        var logs = await _auditoriaService
            .ObtenerLogs()
            .Where(l => l.Accion.ToUpper() == accion.ToUpper())
            .Take(100)
            .ToListAsync();

        return Ok(logs);
    }
}
