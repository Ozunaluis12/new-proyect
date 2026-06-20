using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
/// <summary>
/// Controlador para gestionar las recogidas de clientes.
/// Proporciona operaciones CRUD y mapeo a DTOs de respuesta.
/// </summary>
public class RecogidasController : ControllerBase
{
    private readonly AppDbContext _context;

    /// <summary>
    /// Constructor que recibe el contexto de datos.
    /// </summary>
    public RecogidasController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    /// <summary>
    /// Obtiene todas las recogidas con sus evidencias asociadas.
    /// </summary>
    public async Task<ActionResult<List<RecogidaResponse>>> GetAll()
    {
        var recogidas = await _context.Recogidas
            .AsNoTracking()
            .Include(recogida => recogida.Evidencias)
            .ToListAsync();

        return Ok(recogidas.Select(ToResponse).ToList());
    }

    [HttpGet("{id:int}")]
    /// <summary>
    /// Obtiene una recogida por su identificador, incluyendo evidencias.
    /// </summary>
    public async Task<ActionResult<RecogidaResponse>> GetById(int id)
    {
        var recogida = await _context.Recogidas
            .AsNoTracking()
            .Include(item => item.Evidencias)
            .SingleOrDefaultAsync(item => item.Id == id);

        return recogida is null ? NotFound() : Ok(ToResponse(recogida));
    }

    [HttpPost]
    /// <summary>
    /// Crea una nueva recogida y valida la existencia del cliente y usuario.
    /// </summary>
    public async Task<ActionResult<RecogidaResponse>> Create(RecogidaRequest request)
    {
        if (!await _context.Clientes.AnyAsync(c => c.Id == request.ClienteId))
        {
            return BadRequest(new { mensaje = "Cliente no existe" });
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        var recogida = new Recogida
        {
            ClienteId = request.ClienteId,
            UsuarioId = request.UsuarioId,
            Estado = string.IsNullOrWhiteSpace(request.Estado) ? "Pendiente" : request.Estado,
            CantidadPaquetes = request.CantidadPaquetes,
            Observaciones = request.Observaciones,
        };

        _context.Recogidas.Add(recogida);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = recogida.Id }, ToResponse(recogida));
    }

    [HttpPut("{id:int}")]
    /// <summary>
    /// Actualiza los datos de una recogida existente.
    /// </summary>
    public async Task<IActionResult> Update(int id, RecogidaRequest request)
    {
        var recogida = await _context.Recogidas.FindAsync(id);
        if (recogida is null)
        {
            return NotFound();
        }

        if (!await _context.Clientes.AnyAsync(c => c.Id == request.ClienteId))
        {
            return BadRequest(new { mensaje = "Cliente no existe" });
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        recogida.ClienteId = request.ClienteId;
        recogida.UsuarioId = request.UsuarioId;
        recogida.Estado = request.Estado;
        recogida.CantidadPaquetes = request.CantidadPaquetes;
        recogida.Observaciones = request.Observaciones;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    /// <summary>
    /// Elimina una recogida por su identificador.
    /// </summary>
    public async Task<IActionResult> Delete(int id)
    {
        var recogida = await _context.Recogidas.FindAsync(id);
        if (recogida is null)
        {
            return NotFound();
        }

        _context.Recogidas.Remove(recogida);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>
    /// Convierte la entidad Recogida en un DTO de respuesta.
    /// </summary>
    private static RecogidaResponse ToResponse(Recogida recogida)
    {
        return new RecogidaResponse(
            recogida.Id,
            recogida.ClienteId,
            recogida.UsuarioId,
            recogida.Estado,
            recogida.CantidadPaquetes,
            recogida.Observaciones,
            recogida.Evidencias.Select(evidencia => evidencia.FotoUrl).ToList());
    }
}
