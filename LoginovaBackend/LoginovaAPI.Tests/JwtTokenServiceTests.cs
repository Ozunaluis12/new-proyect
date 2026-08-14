using System.IdentityModel.Tokens.Jwt;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.Extensions.Configuration;

namespace LoginovaAPI.Tests;

public class JwtTokenServiceTests
{
    private static JwtTokenService CreateService()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = "clave-de-prueba-suficientemente-larga-para-hmac-sha256",
                ["Jwt:Issuer"] = "LoginovaTestIssuer",
                ["Jwt:Audience"] = "LoginovaTestAudience",
            })
            .Build();

        return new JwtTokenService(config);
    }

    [Fact]
    public void CreateToken_ConEmpresa_IncluyeClaimEmpresaId()
    {
        var service = CreateService();
        var usuario = new Usuario
        {
            Id = 42,
            EmpresaId = 7,
            Nombre = "Ana",
            Correo = "ana@empresa.com",
            RoleId = 2,
            Role = new Role { Id = 2, Nombre = "Operador" },
        };

        var token = service.CreateToken(usuario);
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        Assert.Equal("42", jwt.Claims.Single(c => c.Type == "userId").Value);
        Assert.Equal("7", jwt.Claims.Single(c => c.Type == "empresaId").Value);
        Assert.Equal("Operador", jwt.Claims.Single(c => c.Type == System.Security.Claims.ClaimTypes.Role).Value);
        Assert.Equal("LoginovaTestIssuer", jwt.Issuer);
        Assert.Contains("LoginovaTestAudience", jwt.Audiences);
    }

    [Fact]
    public void CreateToken_SinEmpresa_RoleSoporte_NoIncluyeClaimEmpresaId()
    {
        // El usuario "Soporte" no pertenece a ninguna empresa (EmpresaId null):
        // el token no debe traer el claim "empresaId", porque su presencia (aunque
        // fuera con un valor artificial) activaría los filtros de tenant y le
        // ocultaría datos que sí debe poder administrar.
        var service = CreateService();
        var usuario = new Usuario
        {
            Id = 1,
            EmpresaId = null,
            Nombre = "Soporte",
            Correo = "soporte@loginova.com",
            RoleId = 5,
            Role = new Role { Id = 5, Nombre = "Soporte" },
        };

        var token = service.CreateToken(usuario);
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        Assert.DoesNotContain(jwt.Claims, c => c.Type == "empresaId");
    }

    [Fact]
    public void CreateToken_ExpiraEnAproximadamente8Horas()
    {
        var service = CreateService();
        var usuario = new Usuario { Id = 1, Nombre = "X", Correo = "x@x.com", RoleId = 1, Role = new Role { Id = 1, Nombre = "Administrador" } };

        var token = service.CreateToken(usuario);
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        var vigencia = jwt.ValidTo - DateTime.UtcNow;
        Assert.InRange(vigencia.TotalHours, 7.9, 8.1);
    }
}
