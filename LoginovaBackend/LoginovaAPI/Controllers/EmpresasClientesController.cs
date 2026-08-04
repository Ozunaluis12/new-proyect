using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// CRM interno del vendedor: administra las empresas que compraron Loginova
/// (una instalación independiente por empresa), sus fechas de membresía y el
/// seguimiento de recordatorios. No tiene relación con <see cref="Cliente"/>
/// (que son los clientes de recogidas dentro de una instalación); esto vive
/// exclusivamente en la instalación del vendedor y solo lo ve el rol
/// Administrador, nunca se delega por permisos como el resto del sistema.
/// </summary>
[ApiController]
[Authorize(Roles = "Administrador")]
[Route("api/[controller]")]
public class EmpresasClientesController : ControllerBase
{
    private static readonly TimeSpan VentanaPorVencer = TimeSpan.FromDays(7);

    private readonly AppDbContext _context;
    private readonly AuditoriaService _auditoria;

    public EmpresasClientesController(AppDbContext context, AuditoriaService auditoria)
    {
        _context = context;
        _auditoria = auditoria;
    }

    /// <summary>Lista todas las empresas, con las más urgentes (vencidas, luego por vencer) primero.</summary>
    [HttpGet]
    public async Task<ActionResult<List<EmpresaClienteResponse>>> GetAll()
    {
        var empresas = await _context.EmpresasClientes
            .AsNoTracking()
            .OrderBy(empresa => empresa.FechaFinMembresia)
            .ToListAsync();

        return Ok(empresas.Select(ToResponse).ToList());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EmpresaClienteResponse>> GetById(int id)
    {
        var empresa = await _context.EmpresasClientes.FindAsync(id);
        return empresa is null ? NotFound() : Ok(ToResponse(empresa));
    }

    [HttpPost]
    public async Task<ActionResult<EmpresaClienteResponse>> Create(EmpresaClienteRequest request)
    {
        var empresa = new EmpresaCliente
        {
            NombreEmpresa = request.NombreEmpresa,
            NombreContacto = request.NombreContacto,
            TelefonoContacto = request.TelefonoContacto,
            CorreoContacto = request.CorreoContacto,
            UrlInstalacion = request.UrlInstalacion,
            FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc),
            FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc),
            MontoMembresia = request.MontoMembresia,
            CicloPago = request.CicloPago,
            Notas = request.Notas,
            Activa = request.Activa,
        };

        _context.EmpresasClientes.Add(empresa);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "EmpresaCliente",
            empresa.Id,
            "CREATE",
            null,
            new { empresa.NombreEmpresa, empresa.FechaInicioMembresia, empresa.FechaFinMembresia },
            $"Nueva empresa cliente registrada: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(GetById), new { id = empresa.Id }, ToResponse(empresa));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, EmpresaClienteRequest request)
    {
        var empresa = await _context.EmpresasClientes.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        var valoresAnteriores = new { empresa.FechaFinMembresia, empresa.Activa };

        empresa.NombreEmpresa = request.NombreEmpresa;
        empresa.NombreContacto = request.NombreContacto;
        empresa.TelefonoContacto = request.TelefonoContacto;
        empresa.CorreoContacto = request.CorreoContacto;
        empresa.UrlInstalacion = request.UrlInstalacion;
        empresa.FechaInicioMembresia = DateTime.SpecifyKind(request.FechaInicioMembresia, DateTimeKind.Utc);
        empresa.FechaFinMembresia = DateTime.SpecifyKind(request.FechaFinMembresia, DateTimeKind.Utc);
        empresa.MontoMembresia = request.MontoMembresia;
        empresa.CicloPago = request.CicloPago;
        empresa.Notas = request.Notas;
        empresa.Activa = request.Activa;

        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "EmpresaCliente",
            empresa.Id,
            "UPDATE",
            valoresAnteriores,
            new { empresa.FechaFinMembresia, empresa.Activa },
            $"Empresa cliente actualizada: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    /// <summary>Marca que se le envió un recordatorio manual (WhatsApp, llamada, etc.) a la empresa hoy.</summary>
    [HttpPut("{id:int}/recordatorio-enviado")]
    public async Task<IActionResult> MarcarRecordatorioEnviado(int id)
    {
        var empresa = await _context.EmpresasClientes.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        empresa.UltimoRecordatorioEnviado = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(ToResponse(empresa));
    }

    /// <summary>Elimina definitivamente una empresa cliente (usar Activa=false para solo darla de baja).</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var empresa = await _context.EmpresasClientes.FindAsync(id);
        if (empresa is null)
        {
            return NotFound();
        }

        _context.EmpresasClientes.Remove(empresa);
        await _context.SaveChangesAsync();

        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "EmpresaCliente",
            id,
            "DELETE",
            new { empresa.NombreEmpresa },
            null,
            $"Empresa cliente eliminada: {empresa.NombreEmpresa}",
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return NoContent();
    }

    private static EmpresaClienteResponse ToResponse(EmpresaCliente empresa)
    {
        var diasParaVencimiento = (int)Math.Ceiling((empresa.FechaFinMembresia - DateTime.UtcNow).TotalDays);
        var estado = diasParaVencimiento < 0
            ? "Vencida"
            : diasParaVencimiento <= VentanaPorVencer.TotalDays
                ? "PorVencer"
                : "Vigente";

        return new EmpresaClienteResponse(
            empresa.Id,
            empresa.NombreEmpresa,
            empresa.NombreContacto,
            empresa.TelefonoContacto,
            empresa.CorreoContacto,
            empresa.UrlInstalacion,
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
