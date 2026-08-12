using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class NormalizaCorreosAMinuscula : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Backfill: cuentas creadas antes de normalizar el correo al
            // guardar/comparar pueden tener mayúsculas o espacios sueltos
            // guardados, lo que impedía iniciar sesión si se escribía el
            // correo con distinta capitalización a como quedó guardado.
            migrationBuilder.Sql("UPDATE usuarios SET correo = LOWER(TRIM(correo)) WHERE correo <> LOWER(TRIM(correo));");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No reversible: no se puede recuperar la capitalización original.
        }
    }
}
