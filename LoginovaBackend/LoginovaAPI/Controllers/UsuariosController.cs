using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize(Roles = "Administrador")]
[Route("api/[controller]")]
public class UsuariosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher _passwordHasher;
    private readonly AuditoriaService _auditoria;

    public UsuariosController(AppDbContext context, PasswordHasher passwordHasher, AuditoriaService auditoria)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _auditoria = auditoria;
    }

    [HttpGet]
    public async Task<ActionResult<List<UsuarioResponse>>> GetAll()
    {
        var usuarios = await _context.Usuarios
            .AsNoTracking()
            .Include(usuario => usuario.Role)
            .Select(usuario => new UsuarioResponse(
                usuario.Id,
                usuario.Nombre,
                usuario.Correo,
                usuario.Rol,
                usuario.Permisos))
            .ToListAsync();

        return Ok(usuarios);
    }

    [HttpPost]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<UsuarioResponse>> Create(UsuarioCreateRequest request)
    {
        if (await _context.Usuarios.AnyAsync(usuario => usuario.Correo == request.Correo))
        {
            return Conflict(new { mensaje = "El correo ya esta registrado" });
        }

        if (!PermisosCatalogo.RolesGestion.Contains(request.Rol))
        {
            return BadRequest(new { mensaje = "Solo se pueden crear Operador o Subadministrador desde el panel" });
        }

        if (!PermisosService.SonPermisosValidos(request.Permisos))
        {
            return BadRequest(new { mensaje = "Uno o más permisos no son válidos" });
        }

        var role = await _context.Roles.SingleOrDefaultAsync(r => r.Nombre == request.Rol);
        if (role is null)
        {
            return BadRequest(new { mensaje = $"Rol invalido: {request.Rol}" });
        }

        var usuario = new Usuario
        {
            Nombre = request.Nombre,
            Correo = request.Correo,
            Password = _passwordHasher.Hash(request.Password),
            RoleId = role.Id,
        };

        usuario.EstablecerPermisos(PermisosService.NormalizarPermisos(request.Permisos));

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            usuario.Id,
            "CREATE",
            null,
            new { usuario.Nombre, usuario.Correo, Rol = request.Rol, Permisos = usuario.Permisos },
            $"Usuario creado: {usuario.Nombre} ({usuario.Correo})",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        usuario.Role = role;
        return CreatedAtAction(nameof(GetAll), ToResponse(usuario));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Update(int id, UsuarioUpdateRequest request)
    {
        var usuario = await _context.Usuarios.FindAsync(id);
        if (usuario is null)
        {
            return NotFound();
        }

        if (await _context.Usuarios.AnyAsync(u => u.Correo == request.Correo && u.Id != id))
        {
            return Conflict(new { mensaje = "El correo ya esta registrado por otro usuario" });
        }

        if (!PermisosCatalogo.RolesGestion.Contains(request.Rol))
        {
            return BadRequest(new { mensaje = "Solo se pueden asignar roles Operador o Subadministrador" });
        }

        if (!PermisosService.SonPermisosValidos(request.Permisos))
        {
            return BadRequest(new { mensaje = "Uno o más permisos no son válidos" });
        }

        var role = await _context.Roles.SingleOrDefaultAsync(r => r.Nombre == request.Rol);
        if (role is null)
        {
            return BadRequest(new { mensaje = $"Rol invalido: {request.Rol}" });
        }

        // Guardar valores anteriores para auditoría
        var valoresAnteriores = new { usuario.Nombre, usuario.Correo, usuario.Rol, Permisos = usuario.Permisos };

        usuario.Nombre = request.Nombre;
        usuario.Correo = request.Correo;
        usuario.RoleId = role.Id;
        usuario.EstablecerPermisos(PermisosService.NormalizarPermisos(request.Permisos));

        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            usuario.Password = _passwordHasher.Hash(request.Password);
        }

        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            usuario.Id,
            "UPDATE",
            valoresAnteriores,
            new { usuario.Nombre, usuario.Correo, Rol = request.Rol, Permisos = usuario.Permisos },
            $"Usuario #{usuario.Id} actualizado",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var usuario = await _context.Usuarios.FindAsync(id);
        if (usuario is null)
        {
            return NotFound();
        }

        // Guardar valores para auditoría antes de eliminar
        var valoresEliminados = new { usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol };

        _context.Usuarios.Remove(usuario);
        await _context.SaveChangesAsync();

        // Registrar en auditoría
        var usuarioIdClaim = int.TryParse(User.FindFirst("userId")?.Value, out var uid) ? uid : 0;
        await _auditoria.RegistrarCambio(
            usuarioIdClaim,
            "Usuario",
            id,
            "DELETE",
            valoresEliminados,
            null,
            $"Usuario eliminado: {usuario.Nombre}",
            HttpContext.Connection.RemoteIpAddress?.ToString()
        );

        return NoContent();
    }

    private static UsuarioResponse ToResponse(Usuario usuario)
    {
        return new UsuarioResponse(usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol, usuario.Permisos);
    }
}
