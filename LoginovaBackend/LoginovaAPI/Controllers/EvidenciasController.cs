using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Controlador que gestiona las evidencias (fotos) de las recogidas. El archivo en
/// sí lo guarda y sirve <see cref="EvidenciaStorageService"/> (fuera de wwwroot,
/// nunca como estático público); aquí solo se administra el registro en base de
/// datos (Evidencia) y la URL resultante. La creación normal de evidencia ocurre
/// como parte de <c>RecogidasController.UpdateEstado</c>; el POST de este
/// controlador es un camino alterno para subir evidencia fuera de ese flujo.
/// </summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class EvidenciasController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly EvidenciaStorageService _storageService;
    private readonly PermisosService _permisosService;

    public EvidenciasController(AppDbContext context, EvidenciaStorageService storageService, PermisosService permisosService)
    {
        _context = context;
        _storageService = storageService;
        _permisosService = permisosService;
    }

    /// <summary>Obtiene la lista completa de evidencias registradas en el sistema.</summary>
    /// <returns>Lista de todas las evidencias.</returns>
    [HttpGet]
    public async Task<ActionResult<List<EvidenciaResponse>>> GetAll()
    {
        var evidencias = await _context.Evidencias.AsNoTracking().ToListAsync();
        return Ok(evidencias.Select(ToResponse).ToList());
    }

    /// <summary>Obtiene una evidencia por su identificador.</summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<EvidenciaResponse>> GetById(int id)
    {
        var evidencia = await _context.Evidencias
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == id);

        return evidencia is null ? NotFound() : Ok(ToResponse(evidencia));
    }

    /// <summary>Obtiene evidencias asociadas a una recogida.</summary>
    [HttpGet("recogida/{recogidaId:int}")]
    public async Task<ActionResult<List<EvidenciaResponse>>> GetByRecogida(int recogidaId)
    {
        if (!await _context.Recogidas.AnyAsync(recogida => recogida.Id == recogidaId))
        {
            return NotFound(new { mensaje = "Recogida no existe" });
        }

        var evidencias = await _context.Evidencias
            .AsNoTracking()
            .Where(evidencia => evidencia.RecogidaId == recogidaId)
            .ToListAsync();

        return Ok(evidencias.Select(ToResponse).ToList());
    }

    /// <summary>Crea una nueva evidencia (foto) para una recogida especifica.</summary>
    /// <param name="request">Datos de la evidencia a crear (recogida, foto, comentario).</param>
    /// <returns>La evidencia creada con su identificador.</returns>
    [HttpPost]
    [RequestFormLimits(MultipartBodyLengthLimit = 10 * 1024 * 1024)]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<ActionResult<EvidenciaResponse>> Create([FromForm] EvidenciaUploadRequest request)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (usuarioIdClaim == 0)
        {
            return Forbid();
        }

        if (!await _permisosService.TienePermisoAsync(usuarioIdClaim, PermisosCatalogo.SubirEvidencias))
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

        if (!_storageService.EsImagenValida(request.Foto, out var errorImagen))
        {
            return BadRequest(new { mensaje = errorImagen });
        }

        var fileName = _storageService.GenerarNombreArchivo(request.Foto);

        await using (var stream = request.Foto.OpenReadStream())
        {
            await _storageService.GuardarAsync(request.RecogidaId, fileName, stream, request.Foto.ContentType);
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

        return CreatedAtAction(nameof(GetById), new { id = evidencia.Id }, ToResponse(evidencia));
    }

    private static EvidenciaResponse ToResponse(Evidencia evidencia) => new(
        evidencia.Id,
        evidencia.RecogidaId,
        evidencia.FotoUrl,
        evidencia.Comentario,
        evidencia.FechaCreacion);

    /// <summary>
    /// Elimina una evidencia por su identificador. Restringido a Administrador:
    /// una evidencia es el respaldo de que una recogida se completó (o de un cobro),
    /// así que un operador no puede borrar su propia prueba.
    /// </summary>
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
