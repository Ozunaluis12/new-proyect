using LoginovaAPI.Data;
using LoginovaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Tests;

/// <summary>
/// Verifica el mecanismo central de aislamiento multi-tenant de AppDbContext:
/// los filtros de consulta globales por EmpresaId (ver AppDbContext.OnModelCreating)
/// y la red de seguridad en SaveChangesAsync que autocompleta/exige EmpresaId.
/// </summary>
public class TenantIsolationTests
{
    private static AppDbContext CreateContext(string dbName, TestTenantContext tenant)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options, tenant);
    }

    [Fact]
    public async Task Query_SoloDevuelveFilasDeLaEmpresaDelTenantActual()
    {
        var dbName = Guid.NewGuid().ToString();
        var seedTenant = new TestTenantContext { EmpresaId = 1 };

        // Sembrar un cliente para la empresa 1 y otro para la empresa 2.
        await using (var seedContext = CreateContext(dbName, seedTenant))
        {
            seedContext.Clientes.Add(new Cliente { EmpresaId = 1, Nombre = "Cliente Empresa 1" });
            await seedContext.SaveChangesAsync();

            seedTenant.EmpresaId = 2;
            seedContext.Clientes.Add(new Cliente { EmpresaId = 2, Nombre = "Cliente Empresa 2" });
            await seedContext.SaveChangesAsync();
        }

        // Empresa 1 solo debe ver su propio cliente.
        var tenant1 = new TestTenantContext { EmpresaId = 1 };
        await using (var context = CreateContext(dbName, tenant1))
        {
            var clientes = await context.Clientes.ToListAsync();

            Assert.Single(clientes);
            Assert.Equal("Cliente Empresa 1", clientes[0].Nombre);
        }

        // Empresa 2 solo debe ver el suyo, nunca el de la empresa 1.
        var tenant2 = new TestTenantContext { EmpresaId = 2 };
        await using (var context = CreateContext(dbName, tenant2))
        {
            var clientes = await context.Clientes.ToListAsync();

            Assert.Single(clientes);
            Assert.Equal("Cliente Empresa 2", clientes[0].Nombre);
        }
    }

    [Fact]
    public async Task Query_SinEmpresaEnContexto_NoDevuelveNingunaFila()
    {
        // Un request sin claim "empresaId" (p. ej. rol Soporte) no debe ver datos
        // de negocio de ninguna empresa por esta vía.
        var dbName = Guid.NewGuid().ToString();
        var seedTenant = new TestTenantContext { EmpresaId = 1 };

        await using (var seedContext = CreateContext(dbName, seedTenant))
        {
            seedContext.Clientes.Add(new Cliente { EmpresaId = 1, Nombre = "Cliente Empresa 1" });
            await seedContext.SaveChangesAsync();
        }

        var sinTenant = new TestTenantContext { EmpresaId = null };
        await using var context = CreateContext(dbName, sinTenant);

        var clientes = await context.Clientes.ToListAsync();

        Assert.Empty(clientes);
    }

    [Fact]
    public async Task SaveChanges_SinEmpresaIdEstampada_LaAutocompletaConLaDelTenantActual()
    {
        var tenant = new TestTenantContext { EmpresaId = 5 };
        await using var context = CreateContext(Guid.NewGuid().ToString(), tenant);

        // No se estampa EmpresaId a mano (queda en el default 0): la red de
        // seguridad de SaveChangesAsync debe completarlo con la del tenant.
        var cliente = new Cliente { Nombre = "Autocompletado" };
        context.Clientes.Add(cliente);
        await context.SaveChangesAsync();

        Assert.Equal(5, cliente.EmpresaId);
    }

    [Fact]
    public async Task SaveChanges_SinEmpresaIdEstampadaYSinTenantAmbiente_Lanza()
    {
        // Si no hay EmpresaId estampada a mano NI contexto de tenant ambiente,
        // guardar en silencio produciría una fila con EmpresaId = 0 invisible
        // para todos. Debe lanzar en vez de corromper el dato.
        var tenant = new TestTenantContext { EmpresaId = null };
        await using var context = CreateContext(Guid.NewGuid().ToString(), tenant);

        context.Clientes.Add(new Cliente { Nombre = "Sin tenant" });

        await Assert.ThrowsAsync<InvalidOperationException>(() => context.SaveChangesAsync());
    }
}
