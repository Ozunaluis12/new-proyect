using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "precision_metros",
                table: "ubicaciones",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "velocidad",
                table: "ubicaciones",
                type: "double precision",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "notificaciones",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    usuario_id = table.Column<int>(type: "integer", nullable: false),
                    fcm_token = table.Column<string>(type: "text", nullable: false),
                    titulo = table.Column<string>(type: "text", nullable: false),
                    cuerpo = table.Column<string>(type: "text", nullable: false),
                    tipo = table.Column<string>(type: "text", nullable: false),
                    datos_adicionales = table.Column<string>(type: "text", nullable: true),
                    recogida_id = table.Column<int>(type: "integer", nullable: true),
                    enviado = table.Column<bool>(type: "boolean", nullable: false),
                    fecha_envio = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    fecha_creacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    leido = table.Column<bool>(type: "boolean", nullable: false),
                    fecha_lectura = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notificaciones", x => x.id);
                    table.ForeignKey(
                        name: "FK_notificaciones_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 6, 22, 18, 13, 39, 355, DateTimeKind.Utc).AddTicks(9464), "pbkdf2$100000$8KVhKwTlVDO3W4/ZLPOHuw==$qnCn17JEoRpmnW5mpFhwxKVI0kK1bbl5m3FYZOiRwZ4=" });

            migrationBuilder.CreateIndex(
                name: "IX_notificaciones_usuario_id",
                table: "notificaciones",
                column: "usuario_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "notificaciones");

            migrationBuilder.DropColumn(
                name: "precision_metros",
                table: "ubicaciones");

            migrationBuilder.DropColumn(
                name: "velocidad",
                table: "ubicaciones");

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 6, 22, 16, 24, 11, 742, DateTimeKind.Utc).AddTicks(1520), "pbkdf2$100000$K3mHljH8+IwT5X3Yzs6jZA==$Zk0KpLcM8F9cBVqWVqRx0cWX297/M2TNGgfxj3LX374=" });
        }
    }
}
