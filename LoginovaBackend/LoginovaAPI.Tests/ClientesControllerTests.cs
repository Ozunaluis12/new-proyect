using LoginovaAPI.Controllers;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Tests;

/// <summary>
/// Prueba ClientesController de punta a punta contra un AppDbContext real
/// (InMemory): el aislamiento multi-tenant a nivel de controller (no solo el
/// filtro de EF ya probado en TenantIsolationTests) y los chequeos de
/// permisos (VerClientes / GestionarClientes).
/// </summary>
public class ClientesControllerTests
{
    private static int _nextRoleId = 20_000;

    private static async Task<(AppDbContext context, ClientesController controller, int usuarioId)> CrearControllerAsync(
        string dbName,
        int empresaId,
        string rol,
        IEnumerable<string> permisos)
    {
        var tenant = new TestTenantContext { EmpresaId = empresaId };
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        var context = new AppDbContext(options, tenant);

        var roleId = System.Threading.Interlocked.Increment(ref _nextRoleId);
        context.Roles.Add(new Role { Id = roleId, Nombre = rol });

        var usuario = new Usuario
        {
            EmpresaId = empresaId,
            Nombre = "Test",
            Correo = $"{Guid.NewGuid()}@test.com",
            Password = "pbkdf2$1$AA==$AA==",
            RoleId = roleId,
        };
        usuario.EstablecerPermisos(permisos);
        context.Usuarios.Add(usuario);
        await context.SaveChangesAsync();

        var controller = new ClientesController(context, new PermisosService(context));
        ControllerTestHelpers.SetUser(controller, usuario.Id, rol, empresaId);

        return (context, controller, usuario.Id);
    }

    [Fact]
    public async Task GetById_ClienteDeOtraEmpresa_DevuelveNotFound_NoElDatoAjeno()
    {
        var dbName = Guid.NewGuid().ToString();

        // Sembrar un cliente en la empresa 2 usando un contexto "de fondo" con ese tenant.
        var tenantSeed = new TestTenantContext { EmpresaId = 2 };
        var seedOptions = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        await using (var seedContext = new AppDbContext(seedOptions, tenantSeed))
        {
            seedContext.Clientes.Add(new Cliente { EmpresaId = 2, Nombre = "Cliente de otra empresa" });
            await seedContext.SaveChangesAsync();
        }

        // Un usuario de la empresa 1, con permiso, intenta leer ese cliente por id.
        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 1, rol: "Operador", [PermisosCatalogo.VerClientes]);
        await using var _ctx = context;

        var resultado = await controller.GetById(1);

        Assert.IsType<NotFoundResult>(resultado.Result);
    }

    [Fact]
    public async Task GetById_ClienteDeLaMismaEmpresa_LoDevuelve()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 1, rol: "Operador", [PermisosCatalogo.VerClientes]);
        await using var _ctx = context;

        context.Clientes.Add(new Cliente { EmpresaId = 1, Nombre = "Cliente propio" });
        await context.SaveChangesAsync();

        var resultado = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(resultado.Result);
        var cliente = Assert.IsType<Cliente>(ok.Value);
        Assert.Equal("Cliente propio", cliente.Nombre);
    }

    [Fact]
    public async Task GetAll_UsuarioSinPermisoVerClientes_DevuelveForbid()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 1, rol: "Operador", []);
        await using var _ctx = context;

        var resultado = await controller.GetAll();

        Assert.IsType<ForbidResult>(resultado.Result);
    }

    [Fact]
    public async Task GetAll_Administrador_NoNecesitaElPermisoExplicito()
    {
        // El rol Administrador tiene bypass total en PermisosService, aunque
        // este usuario de prueba no tenga VerClientes en su lista.
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 1, rol: "Administrador", []);
        await using var _ctx = context;

        var resultado = await controller.GetAll();

        Assert.IsType<OkObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task Create_SinEmpresaIdEnElRequest_LaAsignaAutomaticamenteALaDelUsuario()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 3, rol: "Administrador", []);
        await using var _ctx = context;

        var resultado = await controller.Create(new ClienteRequest("Nuevo cliente", "3000000000", "Calle 1", "Medellín"));

        var created = Assert.IsType<CreatedAtActionResult>(resultado.Result);
        var cliente = Assert.IsType<Cliente>(created.Value);
        Assert.Equal(3, cliente.EmpresaId);
    }

    [Fact]
    public async Task Delete_ClienteDeOtraEmpresa_DevuelveNotFound_NoLoBorra()
    {
        var dbName = Guid.NewGuid().ToString();
        var tenantSeed = new TestTenantContext { EmpresaId = 2 };
        var seedOptions = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        await using (var seedContext = new AppDbContext(seedOptions, tenantSeed))
        {
            seedContext.Clientes.Add(new Cliente { EmpresaId = 2, Nombre = "Cliente protegido" });
            await seedContext.SaveChangesAsync();
        }

        var (context, controller, _) = await CrearControllerAsync(dbName, empresaId: 1, rol: "Administrador", []);
        await using var _ctx = context;

        var resultado = await controller.Delete(1);

        Assert.IsType<NotFoundResult>(resultado);

        // Confirmar que sigue existiendo, visto desde el tenant dueño.
        var tenantCheck = new TestTenantContext { EmpresaId = 2 };
        var checkOptions = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        await using var checkContext = new AppDbContext(checkOptions, tenantCheck);
        Assert.Equal(1, await checkContext.Clientes.CountAsync());
    }
}
