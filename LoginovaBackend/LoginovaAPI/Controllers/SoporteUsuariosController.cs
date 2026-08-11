using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>
/// Administra las cuentas del propio equipo de Soporte (no las empresas
/// clientes). Hoy existe un único usuario Soporte sembrado por la
/// migración; este controlador permite que, si el equipo crece, cada
/// persona tenga su propio login — así la auditoría de acciones de Soporte
/// (crear/activar/suspender empresas, restablecer contraseñas, etc.) queda
/// atribuida a quién la hizo de verdad, no a una cuenta compartida.
/// </summary>
[ApiController]
[Authorize(Roles = "Soporte")]
[Route("api/[controller]")]
public class SoporteUsuariosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher _passwordHasher;

    public SoporteUsuariosController(AppDbContext context, PasswordHasher passwordHasher)
    {
        _context = context;
        _passwordHasher = passwordHasher;
    }

    /// <summary>
    /// Lista las cuentas de Soporte. No necesita IgnoreQueryFilters: el
    /// filtro global de Usuario ya compara EmpresaId == _tenant.EmpresaId, y
    /// para quien llama esto (Soporte, sin claim empresaId) ambos lados son
    /// null, así que el filtro ya deja pasar exactamente las cuentas Soporte.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<UsuarioResponse>>> GetAll()
    {
        var usuarios = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Role)
            .Where(u => u.Role != null && u.Role.Nombre == "Soporte")
            .OrderBy(u => u.Nombre)
            .Select(u => new UsuarioResponse(u.Id, u.Nombre, u.Correo, u.Rol, u.Permisos, u.Activo))
            .ToListAsync();

        return Ok(usuarios);
    }

    [HttpPost]
    public async Task<ActionResult<UsuarioResponse>> Create(CrearSoporteUsuarioRequest request)
    {
        if (await _context.Usuarios.IgnoreQueryFilters().AnyAsync(u => u.Correo == request.Correo))
        {
            return Conflict(new { mensaje = "El correo ya está registrado" });
        }

        var role = await _context.Roles.SingleAsync(r => r.Nombre == "Soporte");

        var usuario = new Usuario
        {
            EmpresaId = null,
            Nombre = request.Nombre,
            Correo = request.Correo,
            Password = _passwordHasher.Hash(request.Password),
            RoleId = role.Id,
            PermisosJson = "[]",
        };

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        usuario.Role = role;
        return CreatedAtAction(nameof(GetAll), new UsuarioResponse(usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol, usuario.Permisos, usuario.Activo));
    }

    /// <summary>Elimina una cuenta de Soporte. No permite que se elimine a sí misma, para evitar un bloqueo accidental sin ninguna cuenta activa.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        if (id == usuarioIdClaim)
        {
            return BadRequest(new { mensaje = "No puedes eliminar tu propia cuenta de Soporte" });
        }

        var usuario = await _context.Usuarios
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Id == id && u.Role != null && u.Role.Nombre == "Soporte");

        if (usuario is null)
        {
            return NotFound();
        }

        _context.Usuarios.Remove(usuario);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
