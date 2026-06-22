using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UsuariosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher _passwordHasher;

    public UsuariosController(AppDbContext context, PasswordHasher passwordHasher)
    {
        _context = context;
        _passwordHasher = passwordHasher;
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
                usuario.Rol))
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

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

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

        var role = await _context.Roles.SingleOrDefaultAsync(r => r.Nombre == request.Rol);
        if (role is null)
        {
            return BadRequest(new { mensaje = $"Rol invalido: {request.Rol}" });
        }

        usuario.Nombre = request.Nombre;
        usuario.Correo = request.Correo;
        usuario.RoleId = role.Id;

        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            usuario.Password = _passwordHasher.Hash(request.Password);
        }

        await _context.SaveChangesAsync();
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

        _context.Usuarios.Remove(usuario);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private static UsuarioResponse ToResponse(Usuario usuario)
    {
        return new UsuarioResponse(usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol);
    }
}
