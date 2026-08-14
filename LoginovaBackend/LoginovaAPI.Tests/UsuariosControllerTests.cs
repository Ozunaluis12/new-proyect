using LoginovaAPI.Controllers;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Tests;

/// <summary>
/// Prueba UsuariosController: la superficie de mayor riesgo de escalación de
/// privilegios (crea/edita cuentas y sus permisos) y otro punto donde el
/// aislamiento multi-tenant debe sostenerse a nivel de controller, no solo
/// en el filtro de EF.
/// </summary>
public class UsuariosControllerTests
{
    private static int _nextRoleId = 40_000;

    private static async Task<(AppDbContext context, UsuariosController controller)> CrearControllerAsync(string dbName, int empresaId)
    {
        var tenant = new TestTenantContext { EmpresaId = empresaId };
        var options = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        var context = new AppDbContext(options, tenant);

        // Roles base que espera el controller (busca por nombre exacto).
        foreach (var nombre in new[] { "Operador", "Subadministrador", "Administrador" })
        {
            if (!await context.Roles.AnyAsync(r => r.Nombre == nombre))
            {
                context.Roles.Add(new Role { Id = System.Threading.Interlocked.Increment(ref _nextRoleId), Nombre = nombre });
            }
        }
        await context.SaveChangesAsync();

        var controller = new UsuariosController(context, new PasswordHasher(), new AuditoriaService(context, tenant), tenant);
        ControllerTestHelpers.SetUser(controller, usuarioId: 1, rol: "Administrador", empresaId: empresaId);

        return (context, controller);
    }

    [Fact]
    public async Task Create_ConRolOperador_LoCreaEnLaEmpresaDelAdminQueLoCrea()
    {
        var (context, controller) = await CrearControllerAsync(Guid.NewGuid().ToString(), empresaId: 5);

        var resultado = await controller.Create(new UsuarioCreateRequest(
            "Nuevo Operador", "operador@empresa.com", "Password123!", "Operador", [PermisosCatalogo.CrearRecogidas]));

        var created = Assert.IsType<CreatedAtActionResult>(resultado.Result);
        var body = Assert.IsType<UsuarioResponse>(created.Value);
        Assert.Equal("Operador", body.Rol);

        var guardado = await context.Usuarios.IgnoreQueryFilters().SingleAsync(u => u.Correo == "operador@empresa.com");
        Assert.Equal(5, guardado.EmpresaId);
    }

    [Fact]
    public async Task Create_IntentandoRolAdministrador_EsRechazado()
    {
        // No debe poder auto-otorgarse (ni otorgarle a nadie) el rol con bypass
        // total de permisos desde este endpoint.
        var (context, controller) = await CrearControllerAsync(Guid.NewGuid().ToString(), empresaId: 1);

        var resultado = await controller.Create(new UsuarioCreateRequest(
            "Intento", "intento@empresa.com", "Password123!", "Administrador", null));

        Assert.IsType<BadRequestObjectResult>(resultado.Result);
        Assert.False(await context.Usuarios.IgnoreQueryFilters().AnyAsync(u => u.Correo == "intento@empresa.com"));
    }

    [Fact]
    public async Task Create_ConCorreoYaRegistradoEnOtraEmpresa_DevuelveConflict()
    {
        // El correo es único a nivel global (lo usa el login sin conocer la
        // empresa todavía), así que el chequeo de duplicado debe cruzar tenants.
        var dbName = Guid.NewGuid().ToString();
        var (context1, controller1) = await CrearControllerAsync(dbName, empresaId: 1);
        await controller1.Create(new UsuarioCreateRequest("Original", "compartido@empresa.com", "Password123!", "Operador", null));

        var (context2, controller2) = await CrearControllerAsync(dbName, empresaId: 2);

        var resultado = await controller2.Create(new UsuarioCreateRequest("Duplicado", "compartido@empresa.com", "Password123!", "Operador", null));

        Assert.IsType<ConflictObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task Create_ConPermisoInventado_DevuelveBadRequest()
    {
        var (context, controller) = await CrearControllerAsync(Guid.NewGuid().ToString(), empresaId: 1);

        var resultado = await controller.Create(new UsuarioCreateRequest(
            "X", "x@empresa.com", "Password123!", "Operador", ["permiso_que_no_existe"]));

        Assert.IsType<BadRequestObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task Update_UsuarioDeOtraEmpresa_DevuelveNotFound()
    {
        var dbName = Guid.NewGuid().ToString();
        var (contextEmpresa2, controllerEmpresa2) = await CrearControllerAsync(dbName, empresaId: 2);
        var creado = await controllerEmpresa2.Create(new UsuarioCreateRequest("Víctima", "victima@empresa.com", "Password123!", "Operador", null));
        var idVictima = Assert.IsType<UsuarioResponse>(Assert.IsType<CreatedAtActionResult>(creado.Result).Value).Id;

        var (_, controllerEmpresa1) = await CrearControllerAsync(dbName, empresaId: 1);

        var resultado = await controllerEmpresa1.Update(idVictima, new UsuarioUpdateRequest(
            "Hackeado", "victima@empresa.com", null, "Operador", null));

        Assert.IsType<NotFoundResult>(resultado);
    }

    [Fact]
    public async Task Update_IntentandoPromoverARolAdministrador_EsRechazado()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller) = await CrearControllerAsync(dbName, empresaId: 1);
        var creado = await controller.Create(new UsuarioCreateRequest("Operador", "op@empresa.com", "Password123!", "Operador", null));
        var id = Assert.IsType<UsuarioResponse>(Assert.IsType<CreatedAtActionResult>(creado.Result).Value).Id;

        var resultado = await controller.Update(id, new UsuarioUpdateRequest("Operador", "op@empresa.com", null, "Administrador", null));

        Assert.IsType<BadRequestObjectResult>(resultado);
        var sinCambios = await context.Usuarios.SingleAsync(u => u.Id == id);
        Assert.Equal("Operador", sinCambios.Rol);
    }

    [Fact]
    public async Task Update_SinPasswordEnElRequest_ConservaLaContraseñaActual()
    {
        var dbName = Guid.NewGuid().ToString();
        var hasher = new PasswordHasher();
        var (context, controller) = await CrearControllerAsync(dbName, empresaId: 1);
        var creado = await controller.Create(new UsuarioCreateRequest("Operador", "op@empresa.com", "PasswordOriginal1", "Operador", null));
        var id = Assert.IsType<UsuarioResponse>(Assert.IsType<CreatedAtActionResult>(creado.Result).Value).Id;

        await controller.Update(id, new UsuarioUpdateRequest("Operador Editado", "op@empresa.com", null, "Operador", null));

        var actualizado = await context.Usuarios.SingleAsync(u => u.Id == id);
        Assert.True(hasher.Verify("PasswordOriginal1", actualizado.Password));
        Assert.Equal("Operador Editado", actualizado.Nombre);
    }

    [Fact]
    public async Task Delete_UsuarioDeOtraEmpresa_DevuelveNotFound_NoLoBorra()
    {
        var dbName = Guid.NewGuid().ToString();
        var (contextEmpresa2, controllerEmpresa2) = await CrearControllerAsync(dbName, empresaId: 2);
        var creado = await controllerEmpresa2.Create(new UsuarioCreateRequest("Víctima", "victima2@empresa.com", "Password123!", "Operador", null));
        var idVictima = Assert.IsType<UsuarioResponse>(Assert.IsType<CreatedAtActionResult>(creado.Result).Value).Id;

        var (_, controllerEmpresa1) = await CrearControllerAsync(dbName, empresaId: 1);

        var resultado = await controllerEmpresa1.Delete(idVictima);

        Assert.IsType<NotFoundResult>(resultado);
        Assert.True(await contextEmpresa2.Usuarios.IgnoreQueryFilters().AnyAsync(u => u.Id == idVictima));
    }
}
