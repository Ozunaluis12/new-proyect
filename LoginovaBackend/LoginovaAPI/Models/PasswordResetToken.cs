using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Token de un solo uso para el flujo de recuperacion de contraseña.
/// Solo se persiste el hash del token, nunca el valor enviado por correo.
/// </summary>
[Table("password_reset_tokens")]
public class PasswordResetToken
{
    [Column("id")]
    public int Id { get; set; }

    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    public Usuario? Usuario { get; set; }

    [Column("token_hash")]
    public string TokenHash { get; set; } = "";

    [Column("expira_en")]
    public DateTime ExpiraEn { get; set; }

    [Column("usado")]
    public bool Usado { get; set; }

    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
