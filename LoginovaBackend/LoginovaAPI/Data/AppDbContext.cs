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

    public DbSet<Permiso> Permisos =>
        Set<Permiso>();

    public DbSet<Cliente> Clientes =>
        Set<Cliente>();

    public DbSet<Recogida> Recogidas =>
        Set<Recogida>();

    public DbSet<Ingreso> Ingresos =>
        Set<Ingreso>();

    public DbSet<CierreCaja> CierresCaja =>
        Set<CierreCaja>();

    public DbSet<Evidencia> Evidencias =>
        Set<Evidencia>();

    public DbSet<Ubicacion> Ubicaciones =>
        Set<Ubicacion>();

    public DbSet<HistorialEstado> HistorialEstados =>
        Set<HistorialEstado>();

    public DbSet<AuditoriaLog> Auditoria =>
        Set<AuditoriaLog>();

    public DbSet<Notificacion> Notificaciones =>
        Set<Notificacion>();

    public DbSet<PasswordResetToken> PasswordResetTokens =>
        Set<PasswordResetToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>().ToTable("usuarios");
        modelBuilder.Entity<Role>().ToTable("roles");
        modelBuilder.Entity<Permiso>().ToTable("permisos");
        modelBuilder.Entity<Cliente>().ToTable("clientes");
        modelBuilder.Entity<Recogida>().ToTable("recogidas");
        modelBuilder.Entity<Ingreso>().ToTable("ingresos");
        modelBuilder.Entity<Evidencia>().ToTable("evidencias");

        modelBuilder.Entity<Usuario>()
            .HasIndex(usuario => usuario.Correo)
            .IsUnique();

        modelBuilder.Entity<Role>()
            .HasData(
                new Role { Id = 1, Nombre = "Administrador", Descripcion = "Control total del sistema" },
                new Role { Id = 2, Nombre = "Operador", Descripcion = "Realiza recogidas" },
                new Role { Id = 3, Nombre = "Cliente", Descripcion = "Consulta servicios" },
                new Role { Id = 4, Nombre = "Subadministrador", Descripcion = "Gestiona operaciones con permisos limitados" });

        modelBuilder.Entity<Permiso>()
            .HasData(
                new Permiso { Id = 1, Nombre = PermisosCatalogo.CrearRecogidas, Descripcion = "Crear nuevas recogidas" },
                new Permiso { Id = 2, Nombre = PermisosCatalogo.EditarRecogidas, Descripcion = "Editar recogidas existentes" },
                new Permiso { Id = 3, Nombre = PermisosCatalogo.CambiarEstadoRecogidas, Descripcion = "Cambiar el estado de una recogida" },
                new Permiso { Id = 4, Nombre = PermisosCatalogo.SubirEvidencias, Descripcion = "Subir fotos y evidencia" },
                new Permiso { Id = 5, Nombre = PermisosCatalogo.RegistrarIngresos, Descripcion = "Registrar dinero cobrado" },
                new Permiso { Id = 6, Nombre = PermisosCatalogo.VerIngresos, Descripcion = "Ver control de ingresos" },
                new Permiso { Id = 7, Nombre = PermisosCatalogo.VerUsuarios, Descripcion = "Ver usuarios del sistema" },
                new Permiso { Id = 8, Nombre = PermisosCatalogo.GestionarUsuarios, Descripcion = "Crear y editar usuarios" },
                new Permiso { Id = 9, Nombre = PermisosCatalogo.VerAuditoria, Descripcion = "Ver historial y auditoría" },
                new Permiso { Id = 10, Nombre = PermisosCatalogo.GestionarNotificaciones, Descripcion = "Gestionar notificaciones" },
                new Permiso { Id = 11, Nombre = PermisosCatalogo.VerUbicaciones, Descripcion = "Ver ubicaciones de operadores" },
                new Permiso { Id = 12, Nombre = PermisosCatalogo.GestionarUbicaciones, Descripcion = "Gestionar ubicaciones de operadores" },
                new Permiso { Id = 13, Nombre = PermisosCatalogo.VerClientes, Descripcion = "Ver clientes del sistema" },
                new Permiso { Id = 14, Nombre = PermisosCatalogo.GestionarClientes, Descripcion = "Crear, editar y eliminar clientes" });

        modelBuilder.Entity<Ubicacion>().ToTable("ubicaciones");
        modelBuilder.Entity<HistorialEstado>().ToTable("historial_estados");
        modelBuilder.Entity<AuditoriaLog>().ToTable("auditoria_logs");

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
            PermisosJson = "[]",
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

        modelBuilder.Entity<Ingreso>()
            .HasOne(ingreso => ingreso.Recogida)
            .WithMany(recogida => recogida.Ingresos)
            .HasForeignKey(ingreso => ingreso.RecogidaId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Ingreso>()
            .HasOne(ingreso => ingreso.Cliente)
            .WithMany(cliente => cliente.Ingresos)
            .HasForeignKey(ingreso => ingreso.ClienteId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Ingreso>()
            .HasOne(ingreso => ingreso.ResponsableUsuario)
            .WithMany(usuario => usuario.IngresosRecibidos)
            .HasForeignKey(ingreso => ingreso.ResponsableUsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Evidencia>()
            .HasOne(evidencia => evidencia.Recogida)
            .WithMany(recogida => recogida.Evidencias)
            .HasForeignKey(evidencia => evidencia.RecogidaId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<CierreCaja>().ToTable("cierres_caja");
        modelBuilder.Entity<CierreCaja>()
            .HasOne(c => c.Operador)
            .WithMany(u => u.CierresCaja)
            .HasForeignKey(c => c.OperadorId)
            .OnDelete(DeleteBehavior.Restrict);

        // Evita cierres de caja duplicados para el mismo operador/día.
        modelBuilder.Entity<CierreCaja>()
            .HasIndex(c => new { c.OperadorId, c.Fecha })
            .IsUnique();

        modelBuilder.Entity<PasswordResetToken>().ToTable("password_reset_tokens");
        modelBuilder.Entity<PasswordResetToken>()
            .HasOne(token => token.Usuario)
            .WithMany()
            .HasForeignKey(token => token.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<PasswordResetToken>()
            .HasIndex(token => new { token.UsuarioId, token.TokenHash });

        // La auditoría se consulta y se escribe en cada request: indexar las columnas de filtro.
        modelBuilder.Entity<AuditoriaLog>()
            .HasIndex(log => log.UsuarioId);
        modelBuilder.Entity<AuditoriaLog>()
            .HasIndex(log => new { log.EntidadTipo, log.EntidadId });
        modelBuilder.Entity<AuditoriaLog>()
            .HasIndex(log => log.Accion);
    }
}
