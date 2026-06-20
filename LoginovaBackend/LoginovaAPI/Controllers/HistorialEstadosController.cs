using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>Controlador que gestiona el historial de cambios de estado en las recogidas.</summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class HistorialEstadosController : ControllerBase
{
    private readonly AppDbContext _context;

    public HistorialEstadosController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>Obtiene todos los registros del historial de estados en el sistema.</summary>
    /// <returns>Lista completa de cambios de estado.</returns>
    [HttpGet]
    public async Task<ActionResult<List<HistorialEstado>>> GetAll()
    {
        return Ok(await _context.HistorialEstados.AsNoTracking().ToListAsync());
    }

    /// <summary>Obtiene un registro especifico del historial por su identificador.</summary>
    /// <param name="id">Identificador del registro historico.</param>
    /// <returns>El registro solicitado o NotFound si no existe.</returns>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<HistorialEstado>> GetById(int id)
    {
        var historial = await _context.HistorialEstados.FindAsync(id);
        return historial is null ? NotFound() : Ok(historial);
    }

    /// <summary>Obtiene el historial completo de cambios de estado para una recogida especifica.</summary>
    /// <param name="recogidaId">Identificador de la recogida.</param>
    /// <returns>Lista de cambios de estado de la recogida o NotFound si la recogida no existe.</returns>
    [HttpGet("recogida/{recogidaId:int}")]
    public async Task<ActionResult<List<HistorialEstado>>> GetByRecogida(int recogidaId)
    {
        if (!await _context.Recogidas.AnyAsync(r => r.Id == recogidaId))
        {
            return NotFound(new { mensaje = "Recogida no existe" });
        }

        var historial = await _context.HistorialEstados
            .AsNoTracking()
            .Where(h => h.RecogidaId == recogidaId)
            .ToListAsync();

        return Ok(historial);
    }

    /// <summary>Crea un nuevo registro de cambio de estado para una recogida.</summary>
    /// <param name="request">Datos del cambio de estado (recogida, estados anterior y nuevo, usuario).</param>
    /// <returns>El registro historico creado con su identificador.</returns>
    [HttpPost]
    public async Task<ActionResult<HistorialEstado>> Create(HistorialEstadoRequest request)
    {
        if (!await _context.Recogidas.AnyAsync(r => r.Id == request.RecogidaId))
        {
            return BadRequest(new { mensaje = "Recogida no existe" });
        }

        if (request.UsuarioId.HasValue && !await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId.Value))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        var historial = new HistorialEstado
        {
            RecogidaId = request.RecogidaId,
            EstadoAnterior = request.EstadoAnterior,
            EstadoNuevo = request.EstadoNuevo,
            UsuarioId = request.UsuarioId,
        };

        _context.HistorialEstados.Add(historial);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = historial.Id }, historial);
    }

    /// <summary>Actualiza un registro del historial de estados.</summary>
    /// <param name="id">Identificador del registro a actualizar.</param>
    /// <param name="request">Nuevos datos del cambio de estado.</param>
    /// <returns>NoContent si la actualizacion fue exitosa.</returns>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, HistorialEstadoRequest request)
    {
        var historial = await _context.HistorialEstados.FindAsync(id);
        if (historial is null)
        {
            return NotFound();
        }

        if (!await _context.Recogidas.AnyAsync(r => r.Id == request.RecogidaId))
        {
            return BadRequest(new { mensaje = "Recogida no existe" });
        }

        if (request.UsuarioId.HasValue && !await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId.Value))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        historial.RecogidaId = request.RecogidaId;
        historial.EstadoAnterior = request.EstadoAnterior;
        historial.EstadoNuevo = request.EstadoNuevo;
        historial.UsuarioId = request.UsuarioId;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Elimina un registro del historial de estados.</summary>
    /// <param name="id">Identificador del registro a eliminar.</param>
    /// <returns>NoContent si la eliminacion fue exitosa.</returns>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var historial = await _context.HistorialEstados.FindAsync(id);
        if (historial is null)
        {
            return NotFound();
        }

        _context.HistorialEstados.Remove(historial);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
