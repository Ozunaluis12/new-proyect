using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa un cliente en el sistema de recogidas.
/// </summary>
[Table("clientes")]
public class Cliente
{
    /// <summary>Identificador unico del cliente.</summary>
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Nombre completo del cliente.</summary>
    [Column("nombre")]
    public string Nombre { get; set; } = "";

    /// <summary>Numero de identificacion tributaria del cliente.</summary>
    [Column("nit")]
    public string? Nit { get; set; }

    /// <summary>Numero de telefono del cliente.</summary>
    [Column("telefono")]
    public string? Telefono { get; set; }

    /// <summary>Correo electronico del cliente.</summary>
    [Column("correo")]
    public string? Correo { get; set; }

    /// <summary>Direccion del cliente.</summary>
    [Column("direccion")]
    public string? Direccion { get; set; }

    /// <summary>Ciudad donde reside el cliente.</summary>
    [Column("ciudad")]
    public string? Ciudad { get; set; }

    /// <summary>Indica si el cliente esta activo en el sistema.</summary>
    [Column("activo")]
    public bool Activo { get; set; } = true;

    /// <summary>Fecha de creacion del registro del cliente.</summary>
    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    /// <summary>Relacion: lista de recogidas asociadas a este cliente.</summary>
    public List<Recogida> Recogidas { get; set; } = [];

    /// <summary>Relacion: historial de ingresos recibidos de este cliente.</summary>
    public List<Ingreso> Ingresos { get; set; } = [];
}
