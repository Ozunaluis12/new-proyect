using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
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
    private readonly PermisosService _permisosService;

    public UbicacionesController(AppDbContext context, PermisosService permisosService)
    {
        _context = context;
        _permisosService = permisosService;
    }

    /// <summary>Obtiene todas las ubicaciones registradas en el sistema.</summary>
    /// <returns>Lista completa de ubicaciones.</returns>
    [HttpGet]
    public async Task<ActionResult<List<UbicacionResponse>>> GetAll()
    {
        if (!await PuedeVerAsync())
        {
            return Forbid();
        }

        var ubicaciones = await _context.Ubicaciones.AsNoTracking().ToListAsync();
        return Ok(ubicaciones.Select(ToResponse).ToList());
    }

    /// <summary>Obtiene una ubicacion especifica por su identificador.</summary>
    /// <param name="id">Identificador de la ubicacion.</param>
    /// <returns>La ubicacion solicitada o NotFound si no existe.</returns>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<UbicacionResponse>> GetById(int id)
    {
        if (!await PuedeVerAsync())
        {
            return Forbid();
        }

        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        return ubicacion is null ? NotFound() : Ok(ToResponse(ubicacion));
    }

    /// <summary>Obtiene todas las ubicaciones registradas por un operador especifico.</summary>
    /// <param name="usuarioId">Identificador del usuario (operador).</param>
    /// <returns>Lista de ubicaciones del usuario o NotFound si el usuario no existe.</returns>
    [HttpGet("usuario/{usuarioId:int}")]
    public async Task<ActionResult<List<UbicacionResponse>>> GetByUsuario(int usuarioId)
    {
        if (!await PuedeVerAsync())
        {
            return Forbid();
        }

        if (!await _context.Usuarios.AnyAsync(u => u.Id == usuarioId))
        {
            return NotFound(new { mensaje = "Usuario no existe" });
        }

        var ubicaciones = await _context.Ubicaciones
            .AsNoTracking()
            .Where(u => u.UsuarioId == usuarioId)
            .ToListAsync();

        return Ok(ubicaciones.Select(ToResponse).ToList());
    }

    /// <summary>Crea una nueva ubicacion para un operador.</summary>
    /// <param name="request">Datos de la ubicacion (latitud, longitud, precision).</param>
    /// <returns>La ubicacion creada con su identificador.</returns>
    [HttpPost]
    public async Task<ActionResult<UbicacionResponse>> Create(UbicacionRequest request)
    {
        // Extrae el usuarioId del token JWT: un operador solo puede reportar su propia ubicacion.
        var usuarioIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (usuarioIdClaim == null || !int.TryParse(usuarioIdClaim.Value, out var usuarioId))
        {
            return Unauthorized(new { mensaje = "Usuario no identificado" });
        }

        var usuario = await _context.Usuarios.FindAsync(usuarioId);
        if (usuario == null)
        {
            return NotFound(new { mensaje = "Usuario no existe" });
        }

        var ubicacion = new Ubicacion
        {
            UsuarioId = usuarioId,
            Latitud = request.Latitud,
            Longitud = request.Longitud,
            PrecisionMetros = request.PrecisionMetros,
            Velocidad = request.Velocidad,
            FechaRegistro = request.FechaRegistro != default ? request.FechaRegistro : DateTime.UtcNow,
        };

        _context.Ubicaciones.Add(ubicacion);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = ubicacion.Id }, ToResponse(ubicacion));
    }

    /// <summary>Actualiza una ubicacion existente.</summary>
    /// <param name="id">Identificador de la ubicacion a actualizar.</param>
    /// <param name="request">Nuevos datos de la ubicacion.</param>
    /// <returns>NoContent si la actualizacion fue exitosa.</returns>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UbicacionRequest request)
    {
        if (!await PuedeGestionarAsync())
        {
            return Forbid();
        }

        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        if (ubicacion is null)
        {
            return NotFound();
        }

        ubicacion.Latitud = request.Latitud;
        ubicacion.Longitud = request.Longitud;
        ubicacion.PrecisionMetros = request.PrecisionMetros;
        ubicacion.Velocidad = request.Velocidad;
        ubicacion.FechaRegistro = request.FechaRegistro != default ? request.FechaRegistro : DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Elimina una ubicacion del sistema.</summary>
    /// <param name="id">Identificador de la ubicacion a eliminar.</param>
    /// <returns>NoContent si la eliminacion fue exitosa.</returns>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (!await PuedeGestionarAsync())
        {
            return Forbid();
        }

        var ubicacion = await _context.Ubicaciones.FindAsync(id);
        if (ubicacion is null)
        {
            return NotFound();
        }

        _context.Ubicaciones.Remove(ubicacion);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private static UbicacionResponse ToResponse(Ubicacion ubicacion) => new(
        ubicacion.Id,
        ubicacion.UsuarioId,
        ubicacion.Latitud,
        ubicacion.Longitud,
        ubicacion.PrecisionMetros,
        ubicacion.Velocidad,
        ubicacion.FechaRegistro);

    private Task<bool> PuedeVerAsync() => TienePermisoAsync(PermisosCatalogo.VerUbicaciones);

    private Task<bool> PuedeGestionarAsync() => TienePermisoAsync(PermisosCatalogo.GestionarUbicaciones);

    // Delega en PermisosService: valida el permiso puntual del usuario sin importar
    // el nombre de su rol (un Subadministrador puede tener los mismos permisos que
    // un Operador); Administrador siempre pasa (bypass total).
    private async Task<bool> TienePermisoAsync(string permiso)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return false;
        }

        return await _permisosService.TienePermisoAsync(usuarioIdClaim, permiso);
    }
}
