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

    /// <summary>
    /// Configura el mapeo de entidades a tablas (nombres en snake_case),
    /// relaciones/claves foráneas y sus reglas de borrado, índices para las
    /// consultas más frecuentes, y los datos semilla (roles, catálogo de
    /// permisos y el usuario Administrador inicial) que EF Core aplica vía
    /// migraciones con <c>HasData</c>.
    /// </summary>
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

        // Roles base del sistema, sembrados con Id fijo para que las migraciones
        // sean deterministas y los RoleId usados en el resto del código (p. ej.
        // comparaciones por nombre de rol) siempre existan.
        modelBuilder.Entity<Role>()
            .HasData(
                new Role { Id = 1, Nombre = "Administrador", Descripcion = "Control total del sistema" },
                new Role { Id = 2, Nombre = "Operador", Descripcion = "Realiza recogidas" },
                new Role { Id = 3, Nombre = "Cliente", Descripcion = "Consulta servicios" },
                new Role { Id = 4, Nombre = "Subadministrador", Descripcion = "Gestiona operaciones con permisos limitados" });

        // Siembra en la tabla Permisos el mismo catálogo definido en
        // PermisosCatalogo, para que la UI de administración pueda listar y
        // asignar permisos sin tener que duplicar los nombres a mano.
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
                new Permiso { Id = 14, Nombre = PermisosCatalogo.GestionarClientes, Descripcion = "Crear, editar y eliminar clientes" },
                new Permiso { Id = 15, Nombre = PermisosCatalogo.CerrarCaja, Descripcion = "Cerrar la caja de un operador o subadministrador" });

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

        modelBuilder.Entity<Usuario>()
            .HasOne(usuario => usuario.Role)
            .WithMany(role => role.Usuarios)
            .HasForeignKey(usuario => usuario.RoleId)
            .OnDelete(DeleteBehavior.Restrict);

        // Hash y fecha fijos a propósito (no PasswordHasher.Hash()/DateTime.UtcNow):
        // si el seed fuera no-determinista, cada "dotnet ef migrations add" futuro
        // generaría una migración espuria que reescribe la contraseña del admin
        // en producción de vuelta a "admin123", borrando cualquier cambio real.
        // Hash de "admin123" con salt fijo, solo para este registro semilla.
        modelBuilder.Entity<Usuario>().HasData(new Usuario
        {
            Id = 1,
            Nombre = "Administrador",
            Correo = "admin@loginova.com",
            Password = "pbkdf2$100000$TG9naW5vdmFTZWVkRml4ZQ==$uGONhA2zkb6zwPFQW3QzzJvOXsdfz88ogmVTbETi7Kw=",
            RoleId = 1,
            PermisosJson = "[]",
            FechaCreacion = new DateTime(2026, 6, 22, 0, 0, 0, DateTimeKind.Utc),
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

        // Cascade aquí a propósito: un ingreso solo tiene sentido junto a su
        // recogida, así que si la recogida se borra, sus ingresos se borran con ella
        // (a diferencia de las relaciones con Usuario/Cliente más abajo, que usan
        // Restrict para no perder historial al borrar a la persona).
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

        // Igual que con Ingresos: las evidencias (fotos) no tienen sentido sin su
        // recogida, así que se borran en cascada junto con ella.
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

        // Un cierre "recoge" los ingresos aún no cerrados de un operador; no hay
        // límite de uno por día porque puede haber un cierre manual a mitad de
        // día y luego el cierre automático nocturno recogiendo el resto.
        modelBuilder.Entity<CierreCaja>()
            .HasIndex(c => new { c.OperadorId, c.Fecha });

        modelBuilder.Entity<Ingreso>()
            .HasOne(i => i.CierreCaja)
            .WithMany(c => c.Ingresos)
            .HasForeignKey(i => i.CierreCajaId)
            .OnDelete(DeleteBehavior.Restrict);

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
