using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text;
using LoginovaAPI.Controllers;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace LoginovaAPI.Tests;

/// <summary>
/// Prueba AuthController (login, forgot-password, reset-password) contra un
/// AppDbContext InMemory real, sin levantar el host HTTP. Es la superficie
/// de mayor riesgo del sistema: cualquier regresión aquí afecta a todos los
/// usuarios, de todas las empresas.
/// </summary>
public class AuthControllerTests
{
    private readonly PasswordHasher _hasher = new();

    private (AppDbContext context, AuthController controller, FakeEmailSender emailSender) CrearController(string dbName)
    {
        var tenant = new TestTenantContext { EmpresaId = null };
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        var context = new AppDbContext(options, tenant);

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = "clave-de-prueba-suficientemente-larga-para-hmac-sha256",
                ["Jwt:Issuer"] = "LoginovaTestIssuer",
                ["Jwt:Audience"] = "LoginovaTestAudience",
            })
            .Build();

        var emailSender = new FakeEmailSender();
        var controller = new AuthController(
            context,
            new JwtTokenService(config),
            _hasher,
            emailSender,
            NullLogger<AuthController>.Instance,
            new FakeWebHostEnvironment { EnvironmentName = "Production" });

        return (context, controller, emailSender);
    }

    private async Task<Usuario> SeedUsuarioAsync(AppDbContext context, string correo, string password, int? empresaId, bool activo = true)
    {
        var role = new Role { Id = System.Threading.Interlocked.Increment(ref _nextRoleId), Nombre = "Administrador" };
        context.Roles.Add(role);

        var usuario = new Usuario
        {
            EmpresaId = empresaId,
            Nombre = "Test",
            Correo = correo,
            Password = _hasher.Hash(password),
            RoleId = role.Id,
            Activo = activo,
        };
        context.Usuarios.Add(usuario);
        await context.SaveChangesAsync();
        return usuario;
    }

    private static int _nextRoleId = 30_000;

    [Fact]
    public async Task Login_ConCredencialesCorrectas_DevuelveTokenYUsuario()
    {
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 7);

        var resultado = await controller.Login(new LoginRequest("ana@empresa.com", "Password123!"));

        var ok = Assert.IsType<OkObjectResult>(resultado.Result);
        var respuesta = Assert.IsType<AuthResponse>(ok.Value);
        Assert.Equal("ana@empresa.com", respuesta.Usuario.Correo);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(respuesta.Token);
        Assert.Equal("7", jwt.Claims.Single(c => c.Type == "empresaId").Value);
    }

    [Fact]
    public async Task Login_CorreoConOtraCapitalizacionYEspacios_FuncionaIgual()
    {
        // Este es el escenario del fix "normaliza el correo a minusculas":
        // el usuario se registró como "ana@empresa.com" pero escribe distinto al loguear.
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        var resultado = await controller.Login(new LoginRequest("  Ana@Empresa.com  ", "Password123!"));

        Assert.IsType<OkObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task Login_PasswordIncorrecta_DevuelveUnauthorized_SinRevelarSiElCorreoExiste()
    {
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        var resultado = await controller.Login(new LoginRequest("ana@empresa.com", "otra-clave"));

        var unauthorized = Assert.IsType<UnauthorizedObjectResult>(resultado.Result);
        Assert.Contains("Credenciales invalidas", unauthorized.Value!.ToString());
    }

    [Fact]
    public async Task Login_CorreoInexistente_DevuelveElMismoMensajeQueUnaPasswordIncorrecta()
    {
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());

        var resultado = await controller.Login(new LoginRequest("nadie@empresa.com", "cualquiera"));

        var unauthorized = Assert.IsType<UnauthorizedObjectResult>(resultado.Result);
        Assert.Contains("Credenciales invalidas", unauthorized.Value!.ToString());
    }

    [Fact]
    public async Task Login_CuentaDesactivada_DevuelveMensajeEspecifico()
    {
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1, activo: false);

        var resultado = await controller.Login(new LoginRequest("ana@empresa.com", "Password123!"));

        var unauthorized = Assert.IsType<UnauthorizedObjectResult>(resultado.Result);
        Assert.Contains("desactivada", unauthorized.Value!.ToString());
    }

    [Fact]
    public async Task Login_IgnoraElTenantAmbiente_BuscaEnTodasLasEmpresas()
    {
        // El login corre sin JWT todavía: si por error dependiera del filtro de
        // tenant (en vez de IgnoreQueryFilters), un usuario de la empresa 2 nunca
        // se encontraría mientras el ITenantContext de ese request apunte a otra
        // empresa (o a ninguna).
        var (context, controller, _) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "usuario-empresa-2@empresa.com", "Password123!", empresaId: 2);

        var resultado = await controller.Login(new LoginRequest("usuario-empresa-2@empresa.com", "Password123!"));

        Assert.IsType<OkObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task ForgotPassword_UsuarioActivo_CreaTokenYEnviaCorreo()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, emailSender) = CrearController(dbName);
        var usuario = await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        await controller.ForgotPassword(new ForgotPasswordRequest("ana@empresa.com"));

        var tokens = await context.PasswordResetTokens.Where(t => t.UsuarioId == usuario.Id).ToListAsync();
        Assert.Single(tokens);
        Assert.False(tokens[0].Usado);
        Assert.Single(emailSender.Enviados);
    }

    [Fact]
    public async Task ForgotPassword_CorreoInexistente_RespondeGenericoSinCrearNadaNiLanzar()
    {
        var (context, controller, emailSender) = CrearController(Guid.NewGuid().ToString());

        var resultado = await controller.ForgotPassword(new ForgotPasswordRequest("nadie@empresa.com"));

        Assert.IsType<OkObjectResult>(resultado);
        Assert.Empty(emailSender.Enviados);
        Assert.Empty(context.PasswordResetTokens);
    }

    [Fact]
    public async Task ForgotPassword_CuentaDesactivada_NoCreaTokenDeRecuperacion()
    {
        // Una cuenta dada de baja no debe poder recuperar acceso por este flujo.
        var (context, controller, emailSender) = CrearController(Guid.NewGuid().ToString());
        await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1, activo: false);

        var resultado = await controller.ForgotPassword(new ForgotPasswordRequest("ana@empresa.com"));

        Assert.IsType<OkObjectResult>(resultado);
        Assert.Empty(emailSender.Enviados);
        Assert.Empty(context.PasswordResetTokens);
    }

    [Fact]
    public async Task ResetPassword_ConCodigoValido_CambiaLaPasswordYMarcaElTokenUsado()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = CrearController(dbName);
        var usuario = await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        const string codigo = "123456";
        context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UsuarioId = usuario.Id,
            TokenHash = HashCodigoIgualQueElControlador(codigo),
            ExpiraEn = DateTime.UtcNow.AddMinutes(10),
        });
        await context.SaveChangesAsync();

        var resultado = await controller.ResetPassword(new ResetPasswordRequest("ana@empresa.com", codigo, "NuevaPassword1"));

        Assert.IsType<NoContentResult>(resultado);
        var actualizado = await context.Usuarios.IgnoreQueryFilters().SingleAsync(u => u.Id == usuario.Id);
        Assert.True(_hasher.Verify("NuevaPassword1", actualizado.Password));
        var token = await context.PasswordResetTokens.SingleAsync();
        Assert.True(token.Usado);
    }

    [Fact]
    public async Task ResetPassword_ConCodigoExpirado_RechazaYNoCambiaLaPassword()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = CrearController(dbName);
        var usuario = await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        const string codigo = "123456";
        context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UsuarioId = usuario.Id,
            TokenHash = HashCodigoIgualQueElControlador(codigo),
            ExpiraEn = DateTime.UtcNow.AddMinutes(-1),
        });
        await context.SaveChangesAsync();

        var resultado = await controller.ResetPassword(new ResetPasswordRequest("ana@empresa.com", codigo, "NuevaPassword1"));

        Assert.IsType<BadRequestObjectResult>(resultado);
        var actualizado = await context.Usuarios.IgnoreQueryFilters().SingleAsync(u => u.Id == usuario.Id);
        Assert.True(_hasher.Verify("Password123!", actualizado.Password));
    }

    [Fact]
    public async Task ResetPassword_ConCodigoIncorrecto_Rechaza()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = CrearController(dbName);
        var usuario = await SeedUsuarioAsync(context, "ana@empresa.com", "Password123!", empresaId: 1);

        context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UsuarioId = usuario.Id,
            TokenHash = HashCodigoIgualQueElControlador("123456"),
            ExpiraEn = DateTime.UtcNow.AddMinutes(10),
        });
        await context.SaveChangesAsync();

        var resultado = await controller.ResetPassword(new ResetPasswordRequest("ana@empresa.com", "000000", "NuevaPassword1"));

        Assert.IsType<BadRequestObjectResult>(resultado);
    }

    /// <summary>Replica LoginovaAPI.Controllers.AuthController.HashCodigo (privado) para sembrar tokens de prueba válidos.</summary>
    private static string HashCodigoIgualQueElControlador(string codigo)
    {
        var bytes = Encoding.UTF8.GetBytes(codigo);
        return Convert.ToHexString(SHA256.HashData(bytes));
    }
}
