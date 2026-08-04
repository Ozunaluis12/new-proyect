using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using LoginovaAPI.Models;
using Microsoft.IdentityModel.Tokens;

namespace LoginovaAPI.Services;

/// <summary>
/// Genera los JWT que autentican a los usuarios frente a la API. El token
/// incluye claims con el id, correo, nombre y rol del usuario, que luego se
/// leen en cada request (por ejemplo, <c>userId</c> lo usa <see cref="AuditoriaActionFilter"/>
/// para saber quién hizo el cambio, y el rol/permisos se validan vía
/// <see cref="PermisosService"/>).
/// </summary>
public class JwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    /// <summary>
    /// Crea y firma (HMAC-SHA256) un JWT para el usuario dado, válido por 8 horas.
    /// La clave de firma sale de la configuración "Jwt:Key".
    /// </summary>
    public string CreateToken(Usuario usuario)
    {
        var jwt = _configuration.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, usuario.Correo),
            new("userId", usuario.Id.ToString()),
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new(ClaimTypes.Name, usuario.Nombre),
            new(ClaimTypes.Role, usuario.Rol),
        };

        // Ancla multi-tenant: de aquí lee ITenantContext la empresa del
        // request para que los filtros de consulta globales de AppDbContext
        // aíslen los datos. Ausente (no se agrega el claim) para el rol
        // Soporte, que no pertenece a ninguna empresa.
        if (usuario.EmpresaId.HasValue)
        {
            claims.Add(new Claim("empresaId", usuario.EmpresaId.Value.ToString()));
        }

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
