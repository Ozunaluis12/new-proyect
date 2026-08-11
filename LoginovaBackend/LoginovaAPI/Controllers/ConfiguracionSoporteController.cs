using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Configuración global del equipo de Soporte: hoy solo las plantillas de
/// mensaje de WhatsApp para el recordatorio de vencimiento, editables sin
/// tener que tocar código. Fila única sembrada por la migración (Id=1).
/// </summary>
[ApiController]
[Authorize(Roles = "Soporte")]
[Route("api/[controller]")]
public class ConfiguracionSoporteController : ControllerBase
{
    private readonly AppDbContext _context;

    public ConfiguracionSoporteController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<ConfiguracionSoporteResponse>> Get()
    {
        var config = await _context.ConfiguracionSoporte.AsNoTracking().FirstOrDefaultAsync(c => c.Id == 1);
        if (config is null)
        {
            return NotFound();
        }

        return Ok(new ConfiguracionSoporteResponse(
            config.PlantillaRecordatorioVigente,
            config.PlantillaRecordatorioVencida));
    }

    [HttpPut]
    public async Task<IActionResult> Update(ActualizarConfiguracionSoporteRequest request)
    {
        var config = await _context.ConfiguracionSoporte.FirstOrDefaultAsync(c => c.Id == 1);
        if (config is null)
        {
            return NotFound();
        }

        config.PlantillaRecordatorioVigente = request.PlantillaRecordatorioVigente;
        config.PlantillaRecordatorioVencida = request.PlantillaRecordatorioVencida;
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
