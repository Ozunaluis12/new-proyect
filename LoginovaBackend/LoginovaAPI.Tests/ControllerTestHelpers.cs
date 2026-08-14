using System.Security.Claims;
using LoginovaAPI.Data;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;

namespace LoginovaAPI.Tests;

/// <summary>IEmailSender de prueba: no envía nada, solo registra qué se intentó enviar.</summary>
internal class FakeEmailSender : IEmailSender
{
    public List<(string Destinatario, string Asunto, string Cuerpo)> Enviados { get; } = [];

    public Task EnviarAsync(string destinatario, string asunto, string cuerpoTexto)
    {
        Enviados.Add((destinatario, asunto, cuerpoTexto));
        return Task.CompletedTask;
    }
}

/// <summary>IWebHostEnvironment mínimo para instanciar controllers fuera del host real.</summary>
internal class FakeWebHostEnvironment : IWebHostEnvironment
{
    public string EnvironmentName { get; set; } = "Production";
    public string ApplicationName { get; set; } = "LoginovaAPI.Tests";
    public string WebRootPath { get; set; } = "";
    public IFileProvider WebRootFileProvider { get; set; } = new NullFileProvider();
    public string ContentRootPath { get; set; } = "";
    public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
}

/// <summary>
/// Utilidades comunes para probar controllers directamente (sin levantar el
/// host HTTP completo): un AppDbContext InMemory aislado por test y un
/// ClaimsPrincipal que imita al que arma JwtTokenService, para ejercitar los
/// mismos chequeos de permisos/tenant que corren en un request real.
/// </summary>
internal static class ControllerTestHelpers
{
    public static AppDbContext CreateContext(TestTenantContext tenant)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options, tenant);
    }

    /// <summary>Arma el mismo tipo de ClaimsPrincipal que JwtTokenService pone en el token, para asignarlo a un controller de prueba.</summary>
    public static void SetUser(ControllerBase controller, int usuarioId, string rol, int? empresaId = null)
    {
        var claims = new List<Claim>
        {
            new("userId", usuarioId.ToString()),
            new(ClaimTypes.Role, rol),
        };
        if (empresaId.HasValue)
        {
            claims.Add(new Claim("empresaId", empresaId.Value.ToString()));
        }

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth")),
            },
        };
    }
}
