using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class SecurityHardening : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "cierres_caja",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    operador_id = table.Column<int>(type: "integer", nullable: false),
                    fecha = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    monto_total = table.Column<decimal>(type: "numeric", nullable: false),
                    observaciones = table.Column<string>(type: "text", nullable: true),
                    creado_por = table.Column<int>(type: "integer", nullable: false),
                    fecha_creacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cierres_caja", x => x.id);
                    table.ForeignKey(
                        name: "FK_cierres_caja_usuarios_operador_id",
                        column: x => x.operador_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "password_reset_tokens",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    usuario_id = table.Column<int>(type: "integer", nullable: false),
                    token_hash = table.Column<string>(type: "text", nullable: false),
                    expira_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    usado = table.Column<bool>(type: "boolean", nullable: false),
                    fecha_creacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_password_reset_tokens", x => x.id);
                    table.ForeignKey(
                        name: "FK_password_reset_tokens_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "permisos",
                columns: new[] { "id", "descripcion", "nombre" },
                values: new object[,]
                {
                    { 7, "Ver usuarios del sistema", "ver_usuarios" },
                    { 8, "Crear y editar usuarios", "gestionar_usuarios" },
                    { 9, "Ver historial y auditoría", "ver_auditoria" },
                    { 10, "Gestionar notificaciones", "gestionar_notificaciones" },
                    { 11, "Ver ubicaciones de operadores", "ver_ubicaciones" },
                    { 12, "Gestionar ubicaciones de operadores", "gestionar_ubicaciones" },
                    { 13, "Ver clientes del sistema", "ver_clientes" },
                    { 14, "Crear, editar y eliminar clientes", "gestionar_clientes" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_auditoria_logs_accion",
                table: "auditoria_logs",
                column: "accion");

            migrationBuilder.CreateIndex(
                name: "IX_auditoria_logs_entidad_tipo_entidad_id",
                table: "auditoria_logs",
                columns: new[] { "entidad_tipo", "entidad_id" });

            migrationBuilder.CreateIndex(
                name: "IX_auditoria_logs_usuario_id",
                table: "auditoria_logs",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "IX_cierres_caja_operador_id_fecha",
                table: "cierres_caja",
                columns: new[] { "operador_id", "fecha" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_password_reset_tokens_usuario_id_token_hash",
                table: "password_reset_tokens",
                columns: new[] { "usuario_id", "token_hash" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "cierres_caja");

            migrationBuilder.DropTable(
                name: "password_reset_tokens");

            migrationBuilder.DropIndex(
                name: "IX_auditoria_logs_accion",
                table: "auditoria_logs");

            migrationBuilder.DropIndex(
                name: "IX_auditoria_logs_entidad_tipo_entidad_id",
                table: "auditoria_logs");

            migrationBuilder.DropIndex(
                name: "IX_auditoria_logs_usuario_id",
                table: "auditoria_logs");

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 14);
        }
    }
}
