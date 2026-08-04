using LoginovaAPI.Data;
using LoginovaAPI.Models;
using System.Text.Json;

namespace LoginovaAPI.Services;

/// <summary>
/// Servicio que registra cambios en las entidades del sistema para auditoría.
/// </summary>
public class AuditoriaService
{
    private readonly AppDbContext _context;
    private readonly ITenantContext _tenant;

    public AuditoriaService(AppDbContext context, ITenantContext tenant)
    {
        _context = context;
        _tenant = tenant;
    }

    /// <summary>
    /// Registra un cambio en la auditoría.
    /// </summary>
    public async Task RegistrarCambio(
        int usuarioId,
        string entidadTipo,
        int entidadId,
        string accion,
        object? valoresAnteriores,
        object? valoresNuevos,
        string? descripcion = null,
        string? ipAddress = null)
    {
        var log = new AuditoriaLog
        {
            // EmpresaId es nullable: null para acciones de Soporte (crear/
            // activar/suspender empresas), que no pertenecen a ninguna. No hay
            // red de seguridad de auto-estampado para esto (AuditoriaLog no es
            // ITenantOwned), así que se estampa explícito aquí.
            EmpresaId = _tenant.EmpresaId,
            UsuarioId = usuarioId,
            EntidadTipo = entidadTipo,
            EntidadId = entidadId,
            Accion = accion,
            ValoresAnteriores = valoresAnteriores != null ? JsonSerializer.Serialize(valoresAnteriores) : null,
            ValoresNuevos = valoresNuevos != null ? JsonSerializer.Serialize(valoresNuevos) : null,
            Descripcion = descripcion,
            FechaCambio = DateTime.UtcNow,
            IpAddress = ipAddress,
        };

        _context.Auditoria.Add(log);
        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// Obtiene todos los logs de auditoría ordenados por fecha descendente.
    /// </summary>
    public IQueryable<AuditoriaLog> ObtenerLogs() =>
        _context.Auditoria.OrderByDescending(l => l.FechaCambio);

    /// <summary>
    /// Obtiene logs de auditoría para una entidad específica.
    /// </summary>
    public IQueryable<AuditoriaLog> ObtenerLogsPorEntidad(string entidadTipo, int entidadId) =>
        _context.Auditoria
            .Where(l => l.EntidadTipo == entidadTipo && l.EntidadId == entidadId)
            .OrderByDescending(l => l.FechaCambio);

    /// <summary>
    /// Obtiene logs de auditoría para un usuario específico.
    /// </summary>
    public IQueryable<AuditoriaLog> ObtenerLogsPorUsuario(int usuarioId) =>
        _context.Auditoria
            .Where(l => l.UsuarioId == usuarioId)
            .OrderByDescending(l => l.FechaCambio);
}
