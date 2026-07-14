using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
/// <summary>
/// Controlador de autenticación que expone endpoints para login,
/// registro de usuario y recuperación de contraseña.
/// </summary>
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly JwtTokenService _jwtTokenService;
    private readonly PasswordHasher _passwordHasher;

    public AuthController(
        AppDbContext context,
        JwtTokenService jwtTokenService,
        PasswordHasher passwordHasher)
    {
        _context = context;
        _jwtTokenService = jwtTokenService;
        _passwordHasher = passwordHasher;
    }

    [HttpPost("login")]
    /// <summary>
    /// Verifica las credenciales de un usuario y devuelve un token JWT.
    /// </summary>
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
    {
        var usuario = await _context.Usuarios
            .Include(item => item.Role)
            .SingleOrDefaultAsync(item => item.Correo == request.Correo);

        if (usuario is null || !_passwordHasher.Verify(request.Password, usuario.Password))
        {
            return Unauthorized(new { mensaje = "Credenciales invalidas" });
        }

        if (!usuario.Password.StartsWith("pbkdf2$", StringComparison.Ordinal))
        {
            usuario.Password = _passwordHasher.Hash(request.Password);
            await _context.SaveChangesAsync();
        }

        return Ok(CreateAuthResponse(usuario));
    }

    [HttpPost("register")]
    /// <summary>
    /// Crea un nuevo usuario con la contraseña hasheada y rol asignado.
    /// </summary>
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request)
    {
        var exists = await _context.Usuarios.AnyAsync(item => item.Correo == request.Correo);
        if (exists)
        {
            return Conflict(new { mensaje = "El correo ya esta registrado" });
        }

        var roleName = "Cliente";
        var role = await _context.Roles.SingleOrDefaultAsync(r => r.Nombre == roleName);
        if (role is null)
        {
            return BadRequest(new { mensaje = $"Rol invalido: {roleName}" });
        }

        var usuario = new Usuario
        {
            Nombre = request.Nombre,
            Correo = request.Correo,
            Password = _passwordHasher.Hash(request.Password),
            RoleId = role.Id,
            PermisosJson = "[]",
        };

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        usuario.Role = role;
        return CreatedAtAction(nameof(Register), CreateAuthResponse(usuario));
    }

    [HttpPost("forgot-password")]
    /// <summary>
    /// Actualiza la contraseña de un usuario existente usando hashing seguro.
    /// </summary>
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request)
    {
        var usuario = await _context.Usuarios.SingleOrDefaultAsync(item => item.Correo == request.Correo);
        if (usuario is null)
        {
            return NotFound(new { mensaje = "Correo no registrado" });
        }

        usuario.Password = _passwordHasher.Hash(request.Password);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private AuthResponse CreateAuthResponse(Usuario usuario)
    {
        return new AuthResponse(
            _jwtTokenService.CreateToken(usuario),
            new UsuarioResponse(usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol, usuario.Permisos));
    }
}
