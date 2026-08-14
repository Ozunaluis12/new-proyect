using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AgregaCiudadOperacionEmpresa : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ciudad_operacion",
                table: "empresas",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "latitud_operacion",
                table: "empresas",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "longitud_operacion",
                table: "empresas",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ciudad_operacion",
                table: "empresas");

            migrationBuilder.DropColumn(
                name: "latitud_operacion",
                table: "empresas");

            migrationBuilder.DropColumn(
                name: "longitud_operacion",
                table: "empresas");
        }
    }
}
