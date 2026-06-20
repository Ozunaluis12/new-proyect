using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Data;

/// <summary>
/// Contexto principal de datos para la aplicación Loginova.
/// Define los DbSet y las configuraciones de mapeo para las entidades.
/// </summary>
public class AppDbContext : DbContext
{
    /// <summary>
    /// Crea un nuevo contexto de base de datos con opciones configuradas.
    /// </summary>
    public AppDbContext(
        DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Usuario> Usuarios =>
        Set<Usuario>();

    public DbSet<Role> Roles =>
        Set<Role>();

    public DbSet<Cliente> Clientes =>
        Set<Cliente>();

    public DbSet<Recogida> Recogidas =>
        Set<Recogida>();

    public DbSet<Evidencia> Evidencias =>
        Set<Evidencia>();

    public DbSet<Ubicacion> Ubicaciones =>
        Set<Ubicacion>();

    public DbSet<HistorialEstado> HistorialEstados =>
        Set<HistorialEstado>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>().ToTable("usuarios");
        modelBuilder.Entity<Role>().ToTable("roles");
        modelBuilder.Entity<Cliente>().ToTable("clientes");
        modelBuilder.Entity<Recogida>().ToTable("recogidas");
        modelBuilder.Entity<Evidencia>().ToTable("evidencias");

        modelBuilder.Entity<Usuario>()
            .HasIndex(usuario => usuario.Correo)
            .IsUnique();

        modelBuilder.Entity<Role>()
            .HasData(
                new Role { Id = 1, Nombre = "Administrador", Descripcion = "Control total del sistema" },
                new Role { Id = 2, Nombre = "Operador", Descripcion = "Realiza recogidas" },
                new Role { Id = 3, Nombre = "Cliente", Descripcion = "Consulta servicios" });

        modelBuilder.Entity<Ubicacion>().ToTable("ubicaciones");
        modelBuilder.Entity<HistorialEstado>().ToTable("historial_estados");

        modelBuilder.Entity<Ubicacion>()
            .HasOne(ubicacion => ubicacion.Usuario)
            .WithMany(usuario => usuario.Ubicaciones)
            .HasForeignKey(ubicacion => ubicacion.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<HistorialEstado>()
            .HasOne(historial => historial.Usuario)
            .WithMany(usuario => usuario.HistorialEstados)
            .HasForeignKey(historial => historial.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<HistorialEstado>()
            .HasOne(historial => historial.Recogida)
            .WithMany(recogida => recogida.HistorialEstados)
            .HasForeignKey(historial => historial.RecogidaId)
            .OnDelete(DeleteBehavior.Restrict);

        var passwordHasher = new PasswordHasher();
        modelBuilder.Entity<Usuario>()
            .HasOne(usuario => usuario.Role)
            .WithMany(role => role.Usuarios)
            .HasForeignKey(usuario => usuario.RoleId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Usuario>().HasData(new Usuario
        {
            Id = 1,
            Nombre = "Administrador",
            Correo = "admin@loginova.com",
            Password = passwordHasher.Hash("admin123"),
            RoleId = 1,
        });

        modelBuilder.Entity<Recogida>()
            .HasOne(recogida => recogida.Cliente)
            .WithMany(cliente => cliente.Recogidas)
            .HasForeignKey(recogida => recogida.ClienteId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Recogida>()
            .HasOne(recogida => recogida.Usuario)
            .WithMany(usuario => usuario.Recogidas)
            .HasForeignKey(recogida => recogida.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Evidencia>()
            .HasOne(evidencia => evidencia.Recogida)
            .WithMany(recogida => recogida.Evidencias)
            .HasForeignKey(evidencia => evidencia.RecogidaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
