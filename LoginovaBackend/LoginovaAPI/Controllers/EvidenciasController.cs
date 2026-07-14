using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>Controlador que gestiona las operaciones de evidencias (fotos) en el sistema.</summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class EvidenciasController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly EvidenciaStorageService _storageService;

    public EvidenciasController(AppDbContext context, EvidenciaStorageService storageService)
    {
        _context = context;
        _storageService = storageService;
    }

    /// <summary>Obtiene la lista completa de evidencias registradas en el sistema.</summary>
    /// <returns>Lista de todas las evidencias.</returns>
    [HttpGet]
    public async Task<ActionResult<List<Evidencia>>> GetAll()
    {
        return Ok(await _context.Evidencias.AsNoTracking().ToListAsync());
    }

    /// <summary>Obtiene una evidencia por su identificador.</summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Evidencia>> GetById(int id)
    {
        var evidencia = await _context.Evidencias
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == id);

        return evidencia is null ? NotFound() : Ok(evidencia);
    }

    /// <summary>Obtiene evidencias asociadas a una recogida.</summary>
    [HttpGet("recogida/{recogidaId:int}")]
    public async Task<ActionResult<List<Evidencia>>> GetByRecogida(int recogidaId)
    {
        if (!await _context.Recogidas.AnyAsync(recogida => recogida.Id == recogidaId))
        {
            return NotFound(new { mensaje = "Recogida no existe" });
        }

        var evidencias = await _context.Evidencias
            .AsNoTracking()
            .Where(evidencia => evidencia.RecogidaId == recogidaId)
            .ToListAsync();

        return Ok(evidencias);
    }

    /// <summary>Crea una nueva evidencia (foto) para una recogida especifica.</summary>
    /// <param name="request">Datos de la evidencia a crear (recogida, foto, comentario).</param>
    /// <returns>La evidencia creada con su identificador.</returns>
    [HttpPost]
    public async Task<ActionResult<Evidencia>> Create([FromForm] EvidenciaUploadRequest request)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        var permisosService = new PermisosService(_context);
        if (!await permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.SubirEvidencias))
        {
            return Forbid();
        }

        if (!await _context.Recogidas.AnyAsync(r => r.Id == request.RecogidaId))
        {
            return BadRequest(new { mensaje = "Recogida no existe" });
        }

        if (request.Foto is null || request.Foto.Length == 0)
        {
            return BadRequest(new { mensaje = "Debes adjuntar una imagen" });
        }

        var uploadsRoot = _storageService.GetUploadsRootPath();
        var recogidaFolder = Path.Combine(uploadsRoot, request.RecogidaId.ToString());
        Directory.CreateDirectory(recogidaFolder);

        var extension = Path.GetExtension(request.Foto.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(recogidaFolder, fileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await request.Foto.CopyToAsync(stream);
        }

        var relativePath = _storageService.BuildRelativePath(request.RecogidaId, fileName);
        var fotoUrl = _storageService.BuildPublicUrl(Request, relativePath);

        var evidencia = new Evidencia
        {
            RecogidaId = request.RecogidaId,
            FotoUrl = fotoUrl,
            Comentario = request.Comentario ?? string.Empty,
        };

        _context.Evidencias.Add(evidencia);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), evidencia);
    }

    /// <summary>Elimina una evidencia por su identificador.</summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var evidencia = await _context.Evidencias.FindAsync(id);
        if (evidencia is null)
        {
            return NotFound();
        }

        _context.Evidencias.Remove(evidencia);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
