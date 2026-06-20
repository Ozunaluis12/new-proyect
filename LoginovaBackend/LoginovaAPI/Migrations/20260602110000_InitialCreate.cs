using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations;

public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Clientes",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                Nombre = table.Column<string>(type: "text", nullable: false),
                Telefono = table.Column<string>(type: "text", nullable: false),
                Direccion = table.Column<string>(type: "text", nullable: false),
                Ciudad = table.Column<string>(type: "text", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Clientes", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Usuarios",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                Nombre = table.Column<string>(type: "text", nullable: false),
                Correo = table.Column<string>(type: "text", nullable: false),
                Password = table.Column<string>(type: "text", nullable: false),
                Rol = table.Column<string>(type: "text", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Usuarios", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Recogidas",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                ClienteId = table.Column<int>(type: "integer", nullable: false),
                UsuarioId = table.Column<int>(type: "integer", nullable: false),
                Estado = table.Column<string>(type: "text", nullable: false),
                CantidadPaquetes = table.Column<int>(type: "integer", nullable: false),
                Observaciones = table.Column<string>(type: "text", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Recogidas", x => x.Id);
                table.ForeignKey(
                    name: "FK_Recogidas_Clientes_ClienteId",
                    column: x => x.ClienteId,
                    principalTable: "Clientes",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
                table.ForeignKey(
                    name: "FK_Recogidas_Usuarios_UsuarioId",
                    column: x => x.UsuarioId,
                    principalTable: "Usuarios",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "Evidencias",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                RecogidaId = table.Column<int>(type: "integer", nullable: false),
                FotoUrl = table.Column<string>(type: "text", nullable: false),
                Comentario = table.Column<string>(type: "text", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Evidencias", x => x.Id);
                table.ForeignKey(
                    name: "FK_Evidencias_Recogidas_RecogidaId",
                    column: x => x.RecogidaId,
                    principalTable: "Recogidas",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.InsertData(
            table: "Usuarios",
            columns: new[] { "Id", "Correo", "Nombre", "Password", "Rol" },
            values: new object[] { 1, "admin@loginova.com", "Administrador", "admin123", "Administrador" });

        migrationBuilder.CreateIndex(
            name: "IX_Evidencias_RecogidaId",
            table: "Evidencias",
            column: "RecogidaId");

        migrationBuilder.CreateIndex(
            name: "IX_Recogidas_ClienteId",
            table: "Recogidas",
            column: "ClienteId");

        migrationBuilder.CreateIndex(
            name: "IX_Recogidas_UsuarioId",
            table: "Recogidas",
            column: "UsuarioId");

        migrationBuilder.CreateIndex(
            name: "IX_Usuarios_Correo",
            table: "Usuarios",
            column: "Correo",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Evidencias");
        migrationBuilder.DropTable(name: "Recogidas");
        migrationBuilder.DropTable(name: "Clientes");
        migrationBuilder.DropTable(name: "Usuarios");
    }
}
