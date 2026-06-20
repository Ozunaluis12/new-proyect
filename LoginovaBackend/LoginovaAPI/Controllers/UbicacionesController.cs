using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>Controlador que gestiona las ubicaciones geograficas de los operadores.</summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UbicacionesController : ControllerBase
{
    private readonly AppDbContext _context;

    public UbicacionesController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>Obtiene todas las ubicaciones registradas en el sistema.</summary>
    /// <returns>Lista completa de ubicaciones.</returns>
    [HttpGet]
    public async Task<ActionResult<List<Ubicacion>>> GetAll()
    {
        return Ok(await _context.Ubicaciones.AsNoTracking().ToListAsync());
    }

    /// <summary>Obtiene una ubicacion especifica por su identificador.</summary>
    /// <param name="id">Identificador de la ubicacion.</param>
    /// <returns>La ubicacion solicitada o NotFound si no existe.</returns>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Ubicacion>> GetById(int id)
    {
        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        return ubicacion is null ? NotFound() : Ok(ubicacion);
    }

    /// <summary>Obtiene todas las ubicaciones registradas por un operador especifico.</summary>
    /// <param name="usuarioId">Identificador del usuario (operador).</param>
    /// <returns>Lista de ubicaciones del usuario o NotFound si el usuario no existe.</returns>
    [HttpGet("usuario/{usuarioId:int}")]
    public async Task<ActionResult<List<Ubicacion>>> GetByUsuario(int usuarioId)
    {
        if (!await _context.Usuarios.AnyAsync(u => u.Id == usuarioId))
        {
            return NotFound(new { mensaje = "Usuario no existe" });
        }

        var ubicaciones = await _context.Ubicaciones
            .AsNoTracking()
            .Where(u => u.UsuarioId == usuarioId)
            .ToListAsync();

        return Ok(ubicaciones);
    }

    /// <summary>Crea una nueva ubicacion para un operador.</summary>
    /// <param name="request">Datos de la ubicacion (usuario, latitud, longitud).</param>
    /// <returns>La ubicacion creada con su identificador.</returns>
    [HttpPost]
    public async Task<ActionResult<Ubicacion>> Create(UbicacionRequest request)
    {
        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        var ubicacion = new Ubicacion
        {
            UsuarioId = request.UsuarioId,
            Latitud = request.Latitud,
            Longitud = request.Longitud,
        };

        _context.Ubicaciones.Add(ubicacion);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = ubicacion.Id }, ubicacion);
    }

    /// <summary>Actualiza una ubicacion existente.</summary>
    /// <param name="id">Identificador de la ubicacion a actualizar.</param>
    /// <param name="request">Nuevos datos de la ubicacion.</param>
    /// <returns>NoContent si la actualizacion fue exitosa.</returns>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UbicacionRequest request)
    {
        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        if (ubicacion is null)
        {
            return NotFound();
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == request.UsuarioId))
        {
            return BadRequest(new { mensaje = "Usuario no existe" });
        }

        ubicacion.UsuarioId = request.UsuarioId;
        ubicacion.Latitud = request.Latitud;
        ubicacion.Longitud = request.Longitud;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Elimina una ubicacion del sistema.</summary>
    /// <param name="id">Identificador de la ubicacion a eliminar.</param>
    /// <returns>NoContent si la eliminacion fue exitosa.</returns>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        if (ubicacion is null)
        {
            return NotFound();
        }

        _context.Ubicaciones.Remove(ubicacion);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
