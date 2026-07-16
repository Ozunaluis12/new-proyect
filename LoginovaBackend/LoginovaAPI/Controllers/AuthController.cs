using System.Security.Cryptography;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[EnableRateLimiting("auth")]
/// <summary>
/// Controlador de autenticación que expone endpoints para login,
/// registro de usuario y recuperación de contraseña.
/// </summary>
public class AuthController : ControllerBase
{
    private const int CodigoRecuperacionValidezMinutos = 15;

    private readonly AppDbContext _context;
    private readonly JwtTokenService _jwtTokenService;
    private readonly PasswordHasher _passwordHasher;
    private readonly IEmailSender _emailSender;
    private readonly ILogger<AuthController> _logger;
    private readonly IWebHostEnvironment _environment;

    public AuthController(
        AppDbContext context,
        JwtTokenService jwtTokenService,
        PasswordHasher passwordHasher,
        IEmailSender emailSender,
        ILogger<AuthController> logger,
        IWebHostEnvironment environment)
    {
        _context = context;
        _jwtTokenService = jwtTokenService;
        _passwordHasher = passwordHasher;
        _emailSender = emailSender;
        _logger = logger;
        _environment = environment;
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
    /// Genera un código de recuperación de un solo uso y lo envía por correo.
    /// Siempre responde con el mismo mensaje genérico, exista o no el correo,
    /// para no revelar qué correos están registrados en el sistema.
    /// </summary>
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request)
    {
        const string respuestaGenerica = "Si el correo está registrado, enviamos un código de recuperación.";

        var usuario = await _context.Usuarios.SingleOrDefaultAsync(item => item.Correo == request.Correo);
        if (usuario is null)
        {
            return Ok(new { mensaje = respuestaGenerica });
        }

        // Invalida cualquier código anterior sin usar: solo debe quedar vigente el
        // último código emitido, para que un código viejo filtrado no sirva para
        // tomar la cuenta si el usuario pidió varios seguidos.
        var tokensPrevios = await _context.PasswordResetTokens
            .Where(item => item.UsuarioId == usuario.Id && !item.Usado)
            .ToListAsync();
        foreach (var previo in tokensPrevios)
        {
            previo.Usado = true;
        }

        // RandomNumberGenerator (criptográficamente seguro) en vez de Random: un
        // código de recuperación predecible sería un vector de toma de cuenta.
        var codigo = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        _context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UsuarioId = usuario.Id,
            TokenHash = HashCodigo(codigo),
            ExpiraEn = DateTime.UtcNow.AddMinutes(CodigoRecuperacionValidezMinutos),
        });

        await _context.SaveChangesAsync();

        try
        {
            await _emailSender.EnviarAsync(
                usuario.Correo,
                "Código de recuperación - Loginova",
                $"Tu código de recuperación es: {codigo}\n\nEs válido por {CodigoRecuperacionValidezMinutos} minutos y solo puede usarse una vez. Si no solicitaste este cambio, ignora este mensaje.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "No se pudo enviar el correo de recuperación a {UsuarioId}", usuario.Id);
        }

        if (_environment.IsDevelopment())
        {
            // Conveniencia solo para desarrollo local: si aún no configuraste el SMTP,
            // el código queda visible en el log para poder probar el flujo sin correo real.
            _logger.LogInformation("[DEV] Código de recuperación para {Correo}: {Codigo}", usuario.Correo, codigo);
        }

        return Ok(new { mensaje = respuestaGenerica });
    }

    [HttpPost("reset-password")]
    /// <summary>
    /// Valida el código de recuperación y actualiza la contraseña usando hashing seguro.
    /// </summary>
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request)
    {
        var usuario = await _context.Usuarios.SingleOrDefaultAsync(item => item.Correo == request.Correo);
        if (usuario is null)
        {
            return BadRequest(new { mensaje = "Código inválido o expirado" });
        }

        var codigoHash = HashCodigo(request.Token);
        var tokenValido = await _context.PasswordResetTokens
            .Where(item => item.UsuarioId == usuario.Id
                && item.TokenHash == codigoHash
                && !item.Usado
                && item.ExpiraEn > DateTime.UtcNow)
            .OrderByDescending(item => item.FechaCreacion)
            .FirstOrDefaultAsync();

        if (tokenValido is null)
        {
            return BadRequest(new { mensaje = "Código inválido o expirado" });
        }

        tokenValido.Usado = true;
        usuario.Password = _passwordHasher.Hash(request.NuevaPassword);

        // Tras un reseteo exitoso se invalida cualquier otro código pendiente del
        // mismo usuario, por si quedó alguno emitido antes que este (evita que un
        // código previo, aún dentro de su ventana de 15 minutos, se pueda usar
        // después de que la contraseña ya cambió).
        var otrosTokens = await _context.PasswordResetTokens
            .Where(item => item.UsuarioId == usuario.Id && !item.Usado && item.Id != tokenValido.Id)
            .ToListAsync();
        foreach (var otro in otrosTokens)
        {
            otro.Usado = true;
        }

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>
    /// Hashea el código de recuperación de 6 dígitos antes de guardarlo en
    /// PasswordResetTokens. Nunca se guarda el código en texto plano: si la base
    /// de datos se filtrara, un atacante no podría leer códigos vigentes y usarlos
    /// para tomar cuentas.
    /// </summary>
    private static string HashCodigo(string codigo)
    {
        var bytes = System.Text.Encoding.UTF8.GetBytes(codigo);
        return Convert.ToHexString(SHA256.HashData(bytes));
    }

    private AuthResponse CreateAuthResponse(Usuario usuario)
    {
        return new AuthResponse(
            _jwtTokenService.CreateToken(usuario),
            new UsuarioResponse(usuario.Id, usuario.Nombre, usuario.Correo, usuario.Rol, usuario.Permisos));
    }
}
