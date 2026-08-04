namespace LoginovaAPI.Models;

/// <summary>
/// Marca las entidades que pertenecen a una <see cref="Empresa"/> (tenant).
/// <see cref="Data.AppDbContext.SaveChangesAsync(System.Threading.CancellationToken)"/>
/// usa esta interfaz para autocompletar <see cref="EmpresaId"/> al crear una
/// fila nueva si no se estampó explícitamente, como red de seguridad además
/// de los filtros de consulta globales.
/// </summary>
public interface ITenantOwned
{
    int EmpresaId { get; set; }
}
