using LoginovaAPI.Models;
using LoginovaAPI.Services;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Data;

/// <summary>
/// Contexto principal de datos para la aplicación Loginova, multi-tenant:
/// cada fila de las tablas de negocio pertenece a exactamente una
/// <see cref="Empresa"/>. El aislamiento entre empresas se garantiza en dos
/// capas: filtros de consulta globales (<see cref="OnModelCreating"/>, vía
/// <see cref="ITenantContext"/>) que se aplican automáticamente a toda
/// lectura, y una red de seguridad en <see cref="SaveChangesAsync"/> que
/// autocompleta <c>EmpresaId</c> al crear una fila si no se estampó a mano.
/// </summary>
public class AppDbContext : DbContext
{
    private readonly ITenantContext _tenant;

    public AppDbContext(DbContextOptions<AppDbContext> options, ITenantContext tenant)
        : base(options)
    {
        _tenant = tenant;
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

    public DbSet<Empresa> Empresas =>
        Set<Empresa>();

    /// <summary>
    /// Configura el mapeo de entidades a tablas (nombres en snake_case),
    /// relaciones/claves foráneas y sus reglas de borrado, índices para las
    /// consultas más frecuentes, los filtros de consulta globales que
    /// aíslan cada empresa, y los datos semilla (roles, catálogo de
    /// permisos y el usuario Soporte inicial) que EF Core aplica vía
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
        modelBuilder.Entity<Empresa>().ToTable("empresas");

        // Correo único global (no por empresa): el login busca por correo
        // sin saber todavía a qué empresa pertenece el usuario (ver
        // AuthController.Login, que por eso usa IgnoreQueryFilters), así
        // que dos empresas no pueden compartir el mismo correo de usuario.
        modelBuilder.Entity<Usuario>()
            .HasIndex(usuario => usuario.Correo)
            .IsUnique();

        modelBuilder.Entity<Usuario>()
            .HasOne(usuario => usuario.Empresa)
            .WithMany(empresa => empresa.Usuarios)
            .HasForeignKey(usuario => usuario.EmpresaId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Empresa>()
            .HasIndex(empresa => empresa.FechaFinMembresia);
        modelBuilder.Entity<Empresa>()
            .HasIndex(empresa => empresa.Activa);

        // Roles base del sistema, sembrados con Id fijo para que las migraciones
        // sean deterministas y los RoleId usados en el resto del código (p. ej.
        // comparaciones por nombre de rol) siempre existan. "Soporte" no
        // pertenece a ninguna empresa: administra las empresas mismas.
        modelBuilder.Entity<Role>()
            .HasData(
                new Role { Id = 1, Nombre = "Administrador", Descripcion = "Control total de su empresa" },
                new Role { Id = 2, Nombre = "Operador", Descripcion = "Realiza recogidas" },
                new Role { Id = 3, Nombre = "Cliente", Descripcion = "Consulta servicios" },
                new Role { Id = 4, Nombre = "Subadministrador", Descripcion = "Gestiona operaciones con permisos limitados" },
                new Role { Id = 5, Nombre = "Soporte", Descripcion = "Administra las empresas clientes del sistema (alta, activación, suspensión)" });

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

        // Único usuario sembrado: Soporte, sin empresa (EmpresaId null). Es
        // quien da de alta la primera empresa real (y su administrador)
        // desde el Panel de Soporte. Hash fijo a propósito (no
        // PasswordHasher.Hash() en vivo): si el seed fuera no-determinista,
        // cada "dotnet ef migrations add" futuro generaría una migración
        // espuria que reescribe esta contraseña en producción.
        modelBuilder.Entity<Usuario>().HasData(new Usuario
        {
            Id = 1,
            EmpresaId = null,
            Nombre = "Soporte",
            Correo = "ozunaluis872@gmail.com",
            Password = "pbkdf2$100000$wPW0sKgu9stR7iOY59HMtA==$HhQnAS35As++7glzUZ/zOBZVbtRx6PCqi9K9O0HR8cg=",
            RoleId = 5,
            PermisosJson = "[]",
            FechaCreacion = new DateTime(2026, 8, 4, 0, 0, 0, DateTimeKind.Utc),
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

        // --- Aislamiento multi-tenant ---
        // FK de EmpresaId -> Empresa e índice, para cada tabla de negocio.
        ConfigurarPropiedadDeEmpresa<Cliente>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<Recogida>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<Evidencia>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<HistorialEstado>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<Ingreso>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<CierreCaja>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<Ubicacion>(modelBuilder);
        ConfigurarPropiedadDeEmpresa<Notificacion>(modelBuilder);

        // AuditoriaLog no implementa ITenantOwned (EmpresaId es nullable, igual
        // que Usuario): las acciones de Soporte no pertenecen a ninguna empresa
        // pero igual deben quedar auditadas. Se configura el FK/índice a mano.
        modelBuilder.Entity<AuditoriaLog>()
            .HasOne<Empresa>()
            .WithMany()
            .HasForeignKey(log => log.EmpresaId)
            .OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<AuditoriaLog>().HasIndex(log => log.EmpresaId);

        // Filtros de consulta globales: toda lectura (incluido FindAsync)
        // queda automáticamente restringida a la empresa del usuario
        // autenticado (o a ninguna fila si es Soporte, que no tiene
        // empresa). Este es el mecanismo central que evita que una empresa
        // vea datos de otra sin depender de que cada controlador se
        // acuerde de filtrar a mano.
        modelBuilder.Entity<Cliente>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<Recogida>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<Evidencia>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<HistorialEstado>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<Ingreso>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<CierreCaja>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<Ubicacion>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<Notificacion>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        modelBuilder.Entity<AuditoriaLog>().HasQueryFilter(e => e.EmpresaId == _tenant.EmpresaId);
        // Usuario es un caso especial: EmpresaId es nullable (null = Soporte).
        // Un usuario Soporte no debe ver usuarios de ninguna empresa por esta
        // vía (los gestiona vía Empresa), y cada usuario normal solo ve los
        // de su propia empresa.
        modelBuilder.Entity<Usuario>().HasQueryFilter(u => u.EmpresaId == _tenant.EmpresaId);
    }

    /// <summary>Configura el FK EmpresaId -> Empresa y su índice para una entidad <see cref="ITenantOwned"/>.</summary>
    private static void ConfigurarPropiedadDeEmpresa<T>(ModelBuilder modelBuilder) where T : class, ITenantOwned
    {
        modelBuilder.Entity<T>()
            .HasOne<Empresa>()
            .WithMany()
            .HasForeignKey(e => e.EmpresaId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<T>().HasIndex(e => e.EmpresaId);
    }

    /// <summary>
    /// Red de seguridad además de los filtros de consulta: si se agrega una
    /// fila nueva de una entidad <see cref="ITenantOwned"/> sin estampar
    /// <c>EmpresaId</c> (quedó en 0), se autocompleta con la empresa del
    /// usuario actual. Si tampoco hay empresa en el contexto (p. ej. un bug
    /// llamando esto desde una acción de Soporte), se lanza una excepción en
    /// vez de guardar silenciosamente una fila con EmpresaId = 0, que
    /// quedaría invisible para todos y sería un dato corrupto.
    /// </summary>
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<ITenantOwned>())
        {
            if (entry.State != Microsoft.EntityFrameworkCore.EntityState.Added || entry.Entity.EmpresaId != 0)
            {
                continue;
            }

            entry.Entity.EmpresaId = _tenant.EmpresaId
                ?? throw new InvalidOperationException(
                    $"No se pudo determinar la empresa (tenant) para crear una fila de {entry.Entity.GetType().Name}: " +
                    "no se estampó EmpresaId explícitamente y no hay contexto de empresa ambiente.");
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
