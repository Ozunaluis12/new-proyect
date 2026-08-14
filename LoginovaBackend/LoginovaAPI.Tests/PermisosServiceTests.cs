using LoginovaAPI.Data;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Tests;

/// <summary>ITenantContext de prueba: valor fijo asignable directamente, sin depender de HttpContext.</summary>
internal class TestTenantContext : ITenantContext
{
    public int? EmpresaId { get; set; }
}

public class PermisosServiceStaticTests
{
    [Fact]
    public void NormalizarPermisos_TrimsDedupesAndDropsEmpty()
    {
        var resultado = PermisosService.NormalizarPermisos(
            [" crear_recogidas ", "CREAR_RECOGIDAS", "", "   ", "ver_clientes"]);

        Assert.Equal(2, resultado.Count);
        Assert.Contains("crear_recogidas", resultado);
        Assert.Contains("ver_clientes", resultado);
    }

    [Fact]
    public void NormalizarPermisos_WithNull_ReturnsEmptyList()
    {
        Assert.Empty(PermisosService.NormalizarPermisos(null));
    }

    [Fact]
    public void SonPermisosValidos_WithNull_ReturnsTrue()
    {
        Assert.True(PermisosService.SonPermisosValidos(null));
    }

    [Fact]
    public void SonPermisosValidos_WithKnownPermisos_ReturnsTrue()
    {
        Assert.True(PermisosService.SonPermisosValidos([
            PermisosCatalogo.CrearRecogidas,
            PermisosCatalogo.VerClientes,
        ]));
    }

    [Fact]
    public void SonPermisosValidos_WithUnknownPermiso_ReturnsFalse()
    {
        Assert.False(PermisosService.SonPermisosValidos(["permiso_inventado"]));
    }
}

public class PermisosServiceTienePermisoTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TestTenantContext _tenant = new() { EmpresaId = 1 };

    public PermisosServiceTienePermisoTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _context = new AppDbContext(options, _tenant);
    }

    public void Dispose() => _context.Dispose();

    private static int _nextRoleId = 10_000;

    private async Task<int> SeedUsuarioAsync(string rol, IEnumerable<string> permisos)
    {
        // Ids altos y únicos por test (Interlocked) para no chocar con los roles
        // 1-5 que EF Core siembra vía HasData en cada base InMemory nueva.
        var roleId = System.Threading.Interlocked.Increment(ref _nextRoleId);
        var role = new Role { Id = roleId, Nombre = rol };
        _context.Roles.Add(role);

        var usuario = new Usuario
        {
            EmpresaId = 1,
            Nombre = "Test",
            Correo = $"{Guid.NewGuid()}@test.com",
            Password = "pbkdf2$1$AA==$AA==",
            RoleId = role.Id,
            Role = role,
        };
        usuario.EstablecerPermisos(permisos);
        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();
        return usuario.Id;
    }

    [Fact]
    public async Task TienePermisoAsync_AdministradorRole_AlwaysTrue_EvenWithoutExplicitPermiso()
    {
        var service = new PermisosService(_context);
        var usuarioId = await SeedUsuarioAsync("Administrador", []);

        var tiene = await service.TienePermisoAsync(usuarioId, PermisosCatalogo.GestionarUsuarios);

        Assert.True(tiene);
    }

    [Fact]
    public async Task TienePermisoAsync_OperadorConPermisoExplicito_ReturnsTrue()
    {
        var service = new PermisosService(_context);
        var usuarioId = await SeedUsuarioAsync("Operador", [PermisosCatalogo.CrearRecogidas]);

        var tiene = await service.TienePermisoAsync(usuarioId, PermisosCatalogo.CrearRecogidas);

        Assert.True(tiene);
    }

    [Fact]
    public async Task TienePermisoAsync_OperadorSinPermiso_ReturnsFalse()
    {
        var service = new PermisosService(_context);
        var usuarioId = await SeedUsuarioAsync("Operador", [PermisosCatalogo.CrearRecogidas]);

        var tiene = await service.TienePermisoAsync(usuarioId, PermisosCatalogo.GestionarUsuarios);

        Assert.False(tiene);
    }

    [Fact]
    public async Task TienePermisoAsync_UsuarioInexistente_ReturnsFalse()
    {
        var service = new PermisosService(_context);

        var tiene = await service.TienePermisoAsync(999_999, PermisosCatalogo.CrearRecogidas);

        Assert.False(tiene);
    }
}
