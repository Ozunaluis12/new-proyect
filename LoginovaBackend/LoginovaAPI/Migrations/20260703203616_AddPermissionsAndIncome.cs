using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddPermissionsAndIncome : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "permisos_json",
                table: "usuarios",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "dinero_recibido",
                table: "recogidas",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "monto_cobrado",
                table: "recogidas",
                type: "numeric",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "permisos",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    descripcion = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_permisos", x => x.id);
                });

            migrationBuilder.InsertData(
                table: "permisos",
                columns: new[] { "id", "descripcion", "nombre" },
                values: new object[,]
                {
                    { 1, "Crear nuevas recogidas", "crear_recogidas" },
                    { 2, "Editar recogidas existentes", "editar_recogidas" },
                    { 3, "Cambiar el estado de una recogida", "cambiar_estado_recogidas" },
                    { 4, "Subir fotos y evidencia", "subir_evidencias" },
                    { 5, "Registrar dinero cobrado", "registrar_ingresos" },
                    { 6, "Ver control de ingresos", "ver_ingresos" }
                });

            migrationBuilder.InsertData(
                table: "roles",
                columns: new[] { "id", "descripcion", "nombre" },
                values: new object[] { 4, "Gestiona operaciones con permisos limitados", "Subadministrador" });

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash", "permisos_json" },
                values: new object[] { new DateTime(2026, 7, 3, 20, 36, 15, 876, DateTimeKind.Utc).AddTicks(5251), "pbkdf2$100000$gTjzWiB+nhhcbAVqygYFZQ==$LImtHYh4ROglOXZtsMx80FP6/3LyE9ybQFXBGvJhcvo=", "[]" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "permisos");

            migrationBuilder.DeleteData(
                table: "roles",
                keyColumn: "id",
                keyValue: 4);

            migrationBuilder.DropColumn(
                name: "permisos_json",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "dinero_recibido",
                table: "recogidas");

            migrationBuilder.DropColumn(
                name: "monto_cobrado",
                table: "recogidas");

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 6, 22, 18, 13, 39, 355, DateTimeKind.Utc).AddTicks(9464), "pbkdf2$100000$8KVhKwTlVDO3W4/ZLPOHuw==$qnCn17JEoRpmnW5mpFhwxKVI0kK1bbl5m3FYZOiRwZ4=" });
        }
    }
}
