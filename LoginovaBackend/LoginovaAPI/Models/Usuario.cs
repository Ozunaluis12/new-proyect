using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;
using System.Text.Json;

namespace LoginovaAPI.Models;

[Table("usuarios")]
public class Usuario
{
    [Column("id")]
    public int Id { get; set; }

    [Column("nombre")]
    public string Nombre { get; set; } = "";

    [Column("correo")]
    public string Correo { get; set; } = "";

    [Column("password_hash")]
    public string Password { get; set; } = "";

    [Column("telefono")]
    public string? Telefono { get; set; }

    [Column("rol_id")]
    public int RoleId { get; set; }

    public Role? Role { get; set; }

    [NotMapped]
    public string Rol => Role?.Nombre ?? string.Empty;

    [Column("permisos_json")]
    public string PermisosJson { get; set; } = "[]";

    [NotMapped]
    public List<string> Permisos => string.IsNullOrWhiteSpace(PermisosJson)
        ? []
        : JsonSerializer.Deserialize<List<string>>(PermisosJson) ?? [];

    public void EstablecerPermisos(IEnumerable<string> permisos)
    {
        PermisosJson = JsonSerializer.Serialize(
            permisos
                .Select(permiso => permiso.Trim())
                .Where(permiso => !string.IsNullOrWhiteSpace(permiso))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList());
    }

    [Column("activo")]
    public bool Activo { get; set; } = true;

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public List<Recogida> Recogidas { get; set; } = new List<Recogida>();
    public List<Ubicacion> Ubicaciones { get; set; } = new List<Ubicacion>();
    public List<HistorialEstado> HistorialEstados { get; set; } = new List<HistorialEstado>();
    public List<Ingreso> IngresosRecibidos { get; set; } = new List<Ingreso>();
    public List<CierreCaja> CierresCaja { get; set; } = new List<CierreCaja>();
}
