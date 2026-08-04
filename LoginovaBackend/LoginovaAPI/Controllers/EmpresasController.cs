using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Panel de Soporte: administra las empresas (tenants) del sistema
/// multi-tenant — altas (junto con el primer Administrador de cada una),
/// edición de membresía, y activación/suspensión. Exclusivo del rol
/// "Soporte", que no pertenece a ninguna empresa y por eso no está sujeto a
/// los filtros de consulta globales de <see cref="AppDbContext"/> (que solo
/// aplican a las entidades <see cref="ITenantOwned"/>, no a <see cref="Empresa"/> misma).
/// </summary>
[ApiController]
[Authorize(Roles = "Soporte")]
[Route("api/[controller]")]
public class EmpresasController : ControllerBase
{
    private static readonly TimeSpan VentanaPorVencer = TimeSpan.FromDays(7);

    private readonly AppDbContext _context;
    private readonly PasswordHasher _passwordHasher;
    private readonly AuditoriaService _auditoria;

    public EmpresasController(AppDbContext context, PasswordHasher passwordHasher, AuditoriaService auditoria)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _auditoria = auditoria;
    }

    [HttpGet]
    public async Task<ActionResult<List<EmpresaResponse>>> GetAll()
    {
        var empresas = await _context.Empresas
            .AsNoTracking()
            .OrderBy(empresa => empresa.FechaFinMembresia)
            .ToListAsync();

        return Ok(empresas.Select(ToResponse).ToList());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EmpresaResponse>> GetById(int id)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        return empresa is null ? NotFound() : Ok(ToResponse(empresa));
    }

    /// <summary>Crea una empresa nueva junto con su primer Administrador, en dos pasos
    /// (primero la empresa para obtener su Id, luego el usuario ya con ese Id) para no
    /// depender de que EF resuelva la FK a través de la navegación antes de que corra
    /// la red de seguridad de <see cref="AppDbContext.SaveChangesAsync"/>.</summary>
    [HttpPost]
    public async Task<ActionResult<EmpresaResponse>> Create(CrearEmpresaRequest request)
    {
        var correoDuplicado = await _context.Usuarios
            .IgnoreQueryFilters()
            .AnyAsync(u => u.EmpresaId != null && u.Correo == request.AdminCorreo);
        // La unicidad real es (EmpresaId, Correo), así que un correo repetido entre
        // empresas distintas es válido; este chequeo es solo una guía útil para
        // Soporte por si reutiliza sin querer el correo de una empresa que ya existe,
        // no una restricción de negocio.

        var empresa = new Empresa
        {
            NombreEmpresa = request.NombreEmpresa,
            NombreContacto = request.NombreContacto,
            TelefonoContacto = request.TelefonoContacto,
            CorreoContacto = request.CorreoContacto,
            FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc),
            FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc),
            MontoMembresia = request.MontoMembresia,
            CicloPago = request.CicloPago,
            Notas = request.Notas,
            Activa = true,
        };
        _context.Empresas.Add(empresa);
        await _context.SaveChangesAsync();

        var role = await _context.Roles.SingleAsync(r => r.Nombre == "Administrador");
        var admin = new Usuario
        {
            EmpresaId = empresa.Id,
            Nombre = request.AdminNombre,
            Correo = request.AdminCorreo,
            Password = _passwordHasher.Hash(request.AdminPassword),
            RoleId = role.Id,
            PermisosJson = "[]",
        };
        _context.Usuarios.Add(admin);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            "CREATE",
            null,
            new { empresa.NombreEmpresa, empresa.FechaInicioMembresia, empresa.FechaFinMembresia, AdminCorreo = admin.Correo },
            $"Nueva empresa registrada: {empresa.NombreEmpresa}{(correoDuplicado ? " (correo de admin repetido con otra empresa)" : "")}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(GetById), new { id = empresa.Id }, ToResponse(empresa));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, ActualizarEmpresaRequest request)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        var valoresAnteriores = new { empresa.FechaFinMembresia, empresa.Activa };

        empresa.NombreEmpresa = request.NombreEmpresa;
        empresa.NombreContacto = request.NombreContacto;
        empresa.TelefonoContacto = request.TelefonoContacto;
        empresa.CorreoContacto = request.CorreoContacto;
        empresa.FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc);
        empresa.FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc);
        empresa.MontoMembresia = request.MontoMembresia;
        empresa.CicloPago = request.CicloPago;
        empresa.Notas = request.Notas;

        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            "UPDATE",
            valoresAnteriores,
            new { empresa.FechaFinMembresia, empresa.Activa },
            $"Empresa actualizada: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    /// <summary>Activa la empresa: sus usuarios recuperan acceso de inmediato.</summary>
    [HttpPut("{id:int}/activar")]
    public async Task<IActionResult> Activar(int id) => await CambiarActiva(id, true);

    /// <summary>Suspende la empresa: TODOS sus usuarios (admin, operadores, etc.)
    /// pierden acceso de inmediato, sin importar el vencimiento de membresía.</summary>
    [HttpPut("{id:int}/suspender")]
    public async Task<IActionResult> Suspender(int id) => await CambiarActiva(id, false);

    private async Task<IActionResult> CambiarActiva(int id, bool activa)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        empresa.Activa = activa;
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Empresa",
            empresa.Id,
            activa ? "ACTIVAR" : "SUSPENDER",
            null,
            new { empresa.Activa },
            $"Empresa {(activa ? "activada" : "suspendida")}: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return Ok(ToResponse(empresa));
    }

    /// <summary>Marca que se le envió un recordatorio manual (WhatsApp, llamada, etc.) a la empresa hoy.</summary>
    [HttpPut("{id:int}/recordatorio-enviado")]
    public async Task<IActionResult> MarcarRecordatorioEnviado(int id)
    {
        var empresa = await _context.Empresas.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        empresa.UltimoRecordatorioEnviado = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(ToResponse(empresa));
    }

    private static EmpresaResponse ToResponse(Empresa empresa)
    {
        var diasParaVencimiento = (int)Math.Ceiling((empresa.FechaFinMembresia - DateTime.UtcNow).TotalDays);
        var estado = !empresa.Activa
            ? "Suspendida"
            : diasParaVencimiento < 0
                ? "Vencida"
                : diasParaVencimiento <= VentanaPorVencer.TotalDays
                    ? "PorVencer"
                    : "Vigente";

        return new EmpresaResponse(
            empresa.Id,
            empresa.NombreEmpresa,
            empresa.NombreContacto,
            empresa.TelefonoContacto,
            empresa.CorreoContacto,
            empresa.FechaInicioMembresia,
            empresa.FechaFinMembresia,
            empresa.MontoMembresia,
            empresa.CicloPago,
            empresa.Notas,
            empresa.Activa,
            empresa.UltimoRecordatorioEnviado,
            empresa.FechaCreacion,
            estado,
            diasParaVencimiento);
    }
}
