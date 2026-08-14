using LoginovaAPI.Controllers;
using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace LoginovaAPI.Tests;

/// <summary>
/// Prueba RecogidasController: el flujo operativo central del negocio.
/// Además del aislamiento multi-tenant y los permisos granulares (patrón ya
/// cubierto en ClientesController/UsuariosController), cubre la regla de
/// negocio más delicada del sistema: a quién se le atribuye el dinero
/// cobrado en <see cref="RecogidasController.UpdateEstado"/>.
/// </summary>
public class RecogidasControllerTests
{
    private static int _nextRoleId = 50_000;
    private static readonly IConfiguration EmptyConfig = new ConfigurationBuilder().Build();

    private static async Task<(AppDbContext context, RecogidasController controller, int usuarioId, int clienteId)>
        CrearEscenarioAsync(string dbName, int empresaId, IEnumerable<string> permisos)
    {
        var tenant = new TestTenantContext { EmpresaId = empresaId };
        var options = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        var context = new AppDbContext(options, tenant);

        var roleId = System.Threading.Interlocked.Increment(ref _nextRoleId);
        context.Roles.Add(new Role { Id = roleId, Nombre = "Operador" });

        var usuario = new Usuario
        {
            EmpresaId = empresaId,
            Nombre = "Operador de prueba",
            Correo = $"{Guid.NewGuid()}@test.com",
            Password = "pbkdf2$1$AA==$AA==",
            RoleId = roleId,
        };
        usuario.EstablecerPermisos(permisos);
        context.Usuarios.Add(usuario);

        var cliente = new Cliente { EmpresaId = empresaId, Nombre = "Cliente de prueba" };
        context.Clientes.Add(cliente);

        await context.SaveChangesAsync();

        var controller = new RecogidasController(
            context,
            new AuditoriaService(context, tenant),
            new EvidenciaStorageService(new FakeWebHostEnvironment(), EmptyConfig),
            new NotificacionService(context, EmptyConfig),
            new PermisosService(context),
            NullLogger<RecogidasController>.Instance);
        ControllerTestHelpers.SetUser(controller, usuario.Id, "Operador", empresaId);
        controller.ControllerContext.HttpContext.Request.Scheme = "https";
        controller.ControllerContext.HttpContext.Request.Host = new HostString("api.test");

        return (context, controller, usuario.Id, cliente.Id);
    }

    private static RecogidaRequest RequestBasico(int clienteId, int usuarioId, string estado = "Pendiente") =>
        new(clienteId, usuarioId, estado, 1, null, null, null, false, null, null);

    [Fact]
    public async Task GetById_RecogidaDeOtraEmpresa_DevuelveNotFound()
    {
        var dbName = Guid.NewGuid().ToString();
        var (contextEmpresa2, _, usuarioEmpresa2, clienteEmpresa2) = await CrearEscenarioAsync(dbName, empresaId: 2, [PermisosCatalogo.CrearRecogidas]);
        contextEmpresa2.Recogidas.Add(new Recogida { EmpresaId = 2, ClienteId = clienteEmpresa2, UsuarioId = usuarioEmpresa2, Estado = "Pendiente", CantidadPaquetes = 1 });
        await contextEmpresa2.SaveChangesAsync();

        var (_, controllerEmpresa1, _, _) = await CrearEscenarioAsync(dbName, empresaId: 1, []);

        var resultado = await controllerEmpresa1.GetById(1);

        Assert.IsType<NotFoundResult>(resultado.Result);
    }

    [Fact]
    public async Task Create_SinPermisoCrearRecogidas_DevuelveForbid()
    {
        var dbName = Guid.NewGuid().ToString();
        var (_, controller, usuarioId, clienteId) = await CrearEscenarioAsync(dbName, empresaId: 1, []);

        var resultado = await controller.Create(RequestBasico(clienteId, usuarioId));

        Assert.IsType<ForbidResult>(resultado.Result);
    }

    [Fact]
    public async Task Create_ConDineroPeroSinPermisoRegistrarIngresos_DevuelveForbid()
    {
        var dbName = Guid.NewGuid().ToString();
        var (_, controller, usuarioId, clienteId) = await CrearEscenarioAsync(dbName, empresaId: 1, [PermisosCatalogo.CrearRecogidas]);

        var request = RequestBasico(clienteId, usuarioId) with { DineroRecibido = true, MontoCobrado = 5000m };
        var resultado = await controller.Create(request);

        Assert.IsType<ForbidResult>(resultado.Result);
    }

    [Fact]
    public async Task Create_Valido_QuedaEnLaEmpresaDelUsuario()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, usuarioId, clienteId) = await CrearEscenarioAsync(dbName, empresaId: 9, [PermisosCatalogo.CrearRecogidas]);

        var resultado = await controller.Create(RequestBasico(clienteId, usuarioId));

        var created = Assert.IsType<CreatedAtActionResult>(resultado.Result);
        var body = Assert.IsType<RecogidaResponse>(created.Value);
        var guardada = await context.Recogidas.SingleAsync(r => r.Id == body.Id);
        Assert.Equal(9, guardada.EmpresaId);
    }

    [Fact]
    public async Task UpdateEstado_ConDinero_CreaIngresoAtribuidoAQuienHaceElCambio_NoAlAsignadoOriginal()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controllerCreador, usuarioCreador, clienteId) = await CrearEscenarioAsync(
            dbName, empresaId: 1, [PermisosCatalogo.CrearRecogidas]);

        var creada = await controllerCreador.Create(RequestBasico(clienteId, usuarioCreador));
        var recogidaId = Assert.IsType<RecogidaResponse>(Assert.IsType<CreatedAtActionResult>(creada.Result).Value).Id;

        // Otro operador (con permisos de cambiar estado + registrar ingresos) es
        // quien realmente completa la recogida y cobra.
        var tenant = new TestTenantContext { EmpresaId = 1 };
        var options = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        var contextOtro = new AppDbContext(options, tenant);
        var roleId = System.Threading.Interlocked.Increment(ref _nextRoleId);
        contextOtro.Roles.Add(new Role { Id = roleId, Nombre = "Operador" });
        var otroUsuario = new Usuario
        {
            EmpresaId = 1,
            Nombre = "Otro operador",
            Correo = $"{Guid.NewGuid()}@test.com",
            Password = "pbkdf2$1$AA==$AA==",
            RoleId = roleId,
        };
        otroUsuario.EstablecerPermisos([PermisosCatalogo.CambiarEstadoRecogidas, PermisosCatalogo.RegistrarIngresos]);
        contextOtro.Usuarios.Add(otroUsuario);
        await contextOtro.SaveChangesAsync();

        var controllerOtro = new RecogidasController(
            contextOtro,
            new AuditoriaService(contextOtro, tenant),
            new EvidenciaStorageService(new FakeWebHostEnvironment(), EmptyConfig),
            new NotificacionService(contextOtro, EmptyConfig),
            new PermisosService(contextOtro),
            NullLogger<RecogidasController>.Instance);
        ControllerTestHelpers.SetUser(controllerOtro, otroUsuario.Id, "Operador", 1);
        controllerOtro.ControllerContext.HttpContext.Request.Scheme = "https";
        controllerOtro.ControllerContext.HttpContext.Request.Host = new HostString("api.test");

        var resultado = await controllerOtro.UpdateEstado(recogidaId, new ActualizarEstadoRecogidaRequest
        {
            Estado = "Recogida",
            DineroRecibido = true,
            MontoCobrado = 25000m,
            FormaPago = "Efectivo",
        });

        Assert.IsType<OkObjectResult>(resultado.Result);

        var ingreso = await context.Ingresos.SingleAsync(i => i.RecogidaId == recogidaId);
        Assert.Equal(otroUsuario.Id, ingreso.ResponsableUsuarioId);
        Assert.Equal(25000m, ingreso.Monto);

        // Contexto nuevo a propósito: "context" ya tenía la Recogida en su
        // change tracker desde el Create() de más arriba, así que releerla ahí
        // devolvería la instancia cacheada (UsuarioId original) en vez del
        // valor recién guardado por contextOtro.
        var tenantVerificacion = new TestTenantContext { EmpresaId = 1 };
        var opcionesVerificacion = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        await using var contextVerificacion = new AppDbContext(opcionesVerificacion, tenantVerificacion);
        var recogidaActualizada = await contextVerificacion.Recogidas.AsNoTracking().SingleAsync(r => r.Id == recogidaId);
        Assert.Equal(otroUsuario.Id, recogidaActualizada.UsuarioId);
        Assert.NotEqual(usuarioCreador, recogidaActualizada.UsuarioId);
    }

    [Fact]
    public async Task UpdateEstado_DineroConEstadoDistintoDeRecogida_DevuelveBadRequest()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, usuarioId, clienteId) = await CrearEscenarioAsync(
            dbName, empresaId: 1, [PermisosCatalogo.CrearRecogidas, PermisosCatalogo.CambiarEstadoRecogidas, PermisosCatalogo.RegistrarIngresos]);
        var creada = await controller.Create(RequestBasico(clienteId, usuarioId));
        var recogidaId = Assert.IsType<RecogidaResponse>(Assert.IsType<CreatedAtActionResult>(creada.Result).Value).Id;

        var resultado = await controller.UpdateEstado(recogidaId, new ActualizarEstadoRecogidaRequest
        {
            Estado = "Cancelada",
            DineroRecibido = true,
            MontoCobrado = 1000m,
            FormaPago = "Efectivo",
        });

        Assert.IsType<BadRequestObjectResult>(resultado.Result);
        Assert.Empty(context.Ingresos);
    }

    [Fact]
    public async Task UpdateEstado_ConFormaPagoInvalida_DevuelveBadRequest()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, usuarioId, clienteId) = await CrearEscenarioAsync(
            dbName, empresaId: 1, [PermisosCatalogo.CrearRecogidas, PermisosCatalogo.CambiarEstadoRecogidas, PermisosCatalogo.RegistrarIngresos]);
        var creada = await controller.Create(RequestBasico(clienteId, usuarioId));
        var recogidaId = Assert.IsType<RecogidaResponse>(Assert.IsType<CreatedAtActionResult>(creada.Result).Value).Id;

        var resultado = await controller.UpdateEstado(recogidaId, new ActualizarEstadoRecogidaRequest
        {
            Estado = "Recogida",
            DineroRecibido = true,
            MontoCobrado = 1000m,
            FormaPago = "Cheque",
        });

        Assert.IsType<BadRequestObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task UpdateEstado_ConEstadoNoPermitidoParaOperador_DevuelveBadRequest()
    {
        var dbName = Guid.NewGuid().ToString();
        var (context, controller, usuarioId, clienteId) = await CrearEscenarioAsync(
            dbName, empresaId: 1, [PermisosCatalogo.CrearRecogidas, PermisosCatalogo.CambiarEstadoRecogidas]);
        var creada = await controller.Create(RequestBasico(clienteId, usuarioId));
        var recogidaId = Assert.IsType<RecogidaResponse>(Assert.IsType<CreatedAtActionResult>(creada.Result).Value).Id;

        var resultado = await controller.UpdateEstado(recogidaId, new ActualizarEstadoRecogidaRequest { Estado = "Entregada" });

        Assert.IsType<BadRequestObjectResult>(resultado.Result);
    }

    [Fact]
    public async Task Delete_RecogidaDeOtraEmpresa_DevuelveNotFound()
    {
        var dbName = Guid.NewGuid().ToString();
        var (contextEmpresa2, controllerEmpresa2, usuarioEmpresa2, clienteEmpresa2) = await CrearEscenarioAsync(
            dbName, empresaId: 2, [PermisosCatalogo.CrearRecogidas]);
        var creada = await controllerEmpresa2.Create(RequestBasico(clienteEmpresa2, usuarioEmpresa2));
        var recogidaId = Assert.IsType<RecogidaResponse>(Assert.IsType<CreatedAtActionResult>(creada.Result).Value).Id;

        var (_, controllerEmpresa1, _, _) = await CrearEscenarioAsync(dbName, empresaId: 1, []);

        var resultado = await controllerEmpresa1.Delete(recogidaId);

        Assert.IsType<NotFoundResult>(resultado);
        Assert.True(await contextEmpresa2.Recogidas.AnyAsync(r => r.Id == recogidaId));
    }
}
