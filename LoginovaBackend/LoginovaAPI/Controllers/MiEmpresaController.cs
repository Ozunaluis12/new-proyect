using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Datos de la propia empresa del usuario autenticado. A diferencia de
/// <see cref="EmpresasController"/> (exclusivo de Soporte, administra TODAS
/// las empresas), este controlador es para cualquier usuario normal de una
/// empresa consultando la suya propia — hoy solo se usa para mostrar el
/// nombre de la empresa en el botón de "Contactar Soporte".
/// </summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class MiEmpresaController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITenantContext _tenant;

    public MiEmpresaController(AppDbContext context, ITenantContext tenant)
    {
        _context = context;
        _tenant = tenant;
    }

    [HttpGet]
    public async Task<ActionResult<MiEmpresaResponse>> Get()
    {
        if (_tenant.EmpresaId is null)
        {
            // Soporte (sin empresa) no tiene "mi empresa".
            return NotFound();
        }

        var empresa = await _context.Empresas
            .AsNoTracking()
            .Where(e => e.Id == _tenant.EmpresaId)
            .Select(e => new MiEmpresaResponse(
                e.Id,
                e.NombreEmpresa,
                e.CiudadOperacion,
                e.LatitudOperacion,
                e.LongitudOperacion))
            .FirstOrDefaultAsync();

        return empresa is null ? NotFound() : Ok(empresa);
    }
}
