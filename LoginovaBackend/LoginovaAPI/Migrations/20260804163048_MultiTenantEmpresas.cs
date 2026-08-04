using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class MultiTenantEmpresas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // "Empezar limpio": se pasa a multi-tenant real y las 10 tablas
            // operativas van a exigir empresa_id (la mayoría NOT NULL con FK a
            // empresas). Los datos de prueba que existen hoy no pertenecen a
            // ninguna empresa real, así que en vez de inventarles una empresa
            // se descartan explícitamente aquí (orden: hijos antes que padres,
            // para no violar FKs existentes). El usuario id=1 (el Administrador
            // sembrado original) se conserva a propósito: el UpdateData de más
            // abajo lo convierte en el usuario Soporte inicial.
            migrationBuilder.Sql(@"
                DELETE FROM notificaciones;
                DELETE FROM auditoria_logs;
                DELETE FROM ubicaciones;
                DELETE FROM historial_estados;
                DELETE FROM evidencias;
                DELETE FROM ingresos;
                DELETE FROM cierres_caja;
                DELETE FROM recogidas;
                DELETE FROM clientes;
                DELETE FROM password_reset_tokens;
                DELETE FROM usuarios WHERE id <> 1;
            ");

            migrationBuilder.DropTable(
                name: "empresas_clientes");

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "usuarios",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "ubicaciones",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "recogidas",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "notificaciones",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "ingresos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "historial_estados",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "evidencias",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "clientes",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "cierres_caja",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "empresa_id",
                table: "auditoria_logs",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "empresas",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    nombre_empresa = table.Column<string>(type: "text", nullable: false),
                    nombre_contacto = table.Column<string>(type: "text", nullable: true),
                    telefono_contacto = table.Column<string>(type: "text", nullable: true),
                    correo_contacto = table.Column<string>(type: "text", nullable: true),
                    fecha_inicio_membresia = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    fecha_fin_membresia = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    monto_membresia = table.Column<decimal>(type: "numeric", nullable: true),
                    ciclo_pago = table.Column<string>(type: "text", nullable: true),
                    notas = table.Column<string>(type: "text", nullable: true),
                    activa = table.Column<bool>(type: "boolean", nullable: false),
                    ultimo_recordatorio_enviado = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    fecha_creacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_empresas", x => x.id);
                });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "id",
                keyValue: 1,
                column: "descripcion",
                value: "Control total de su empresa");

            migrationBuilder.InsertData(
                table: "roles",
                columns: new[] { "id", "descripcion", "nombre" },
                values: new object[] { 5, "Administra las empresas clientes del sistema (alta, activación, suspensión)", "Soporte" });

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "correo", "empresa_id", "fecha_creacion", "nombre", "password_hash", "rol_id" },
                values: new object[] { "ozunaluis872@gmail.com", null, new DateTime(2026, 8, 4, 0, 0, 0, 0, DateTimeKind.Utc), "Soporte", "pbkdf2$100000$wPW0sKgu9stR7iOY59HMtA==$HhQnAS35As++7glzUZ/zOBZVbtRx6PCqi9K9O0HR8cg=", 5 });

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_empresa_id",
                table: "usuarios",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_ubicaciones_empresa_id",
                table: "ubicaciones",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_recogidas_empresa_id",
                table: "recogidas",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_notificaciones_empresa_id",
                table: "notificaciones",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_ingresos_empresa_id",
                table: "ingresos",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_historial_estados_empresa_id",
                table: "historial_estados",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_evidencias_empresa_id",
                table: "evidencias",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_clientes_empresa_id",
                table: "clientes",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_cierres_caja_empresa_id",
                table: "cierres_caja",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_auditoria_logs_empresa_id",
                table: "auditoria_logs",
                column: "empresa_id");

            migrationBuilder.CreateIndex(
                name: "IX_empresas_activa",
                table: "empresas",
                column: "activa");

            migrationBuilder.CreateIndex(
                name: "IX_empresas_fecha_fin_membresia",
                table: "empresas",
                column: "fecha_fin_membresia");

            migrationBuilder.AddForeignKey(
                name: "FK_auditoria_logs_empresas_empresa_id",
                table: "auditoria_logs",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_cierres_caja_empresas_empresa_id",
                table: "cierres_caja",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_clientes_empresas_empresa_id",
                table: "clientes",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_evidencias_empresas_empresa_id",
                table: "evidencias",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_historial_estados_empresas_empresa_id",
                table: "historial_estados",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ingresos_empresas_empresa_id",
                table: "ingresos",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_notificaciones_empresas_empresa_id",
                table: "notificaciones",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_recogidas_empresas_empresa_id",
                table: "recogidas",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ubicaciones_empresas_empresa_id",
                table: "ubicaciones",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_usuarios_empresas_empresa_id",
                table: "usuarios",
                column: "empresa_id",
                principalTable: "empresas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_auditoria_logs_empresas_empresa_id",
                table: "auditoria_logs");

            migrationBuilder.DropForeignKey(
                name: "FK_cierres_caja_empresas_empresa_id",
                table: "cierres_caja");

            migrationBuilder.DropForeignKey(
                name: "FK_clientes_empresas_empresa_id",
                table: "clientes");

            migrationBuilder.DropForeignKey(
                name: "FK_evidencias_empresas_empresa_id",
                table: "evidencias");

            migrationBuilder.DropForeignKey(
                name: "FK_historial_estados_empresas_empresa_id",
                table: "historial_estados");

            migrationBuilder.DropForeignKey(
                name: "FK_ingresos_empresas_empresa_id",
                table: "ingresos");

            migrationBuilder.DropForeignKey(
                name: "FK_notificaciones_empresas_empresa_id",
                table: "notificaciones");

            migrationBuilder.DropForeignKey(
                name: "FK_recogidas_empresas_empresa_id",
                table: "recogidas");

            migrationBuilder.DropForeignKey(
                name: "FK_ubicaciones_empresas_empresa_id",
                table: "ubicaciones");

            migrationBuilder.DropForeignKey(
                name: "FK_usuarios_empresas_empresa_id",
                table: "usuarios");

            migrationBuilder.DropTable(
                name: "empresas");

            migrationBuilder.DropIndex(
                name: "IX_usuarios_empresa_id",
                table: "usuarios");

            migrationBuilder.DropIndex(
                name: "IX_ubicaciones_empresa_id",
                table: "ubicaciones");

            migrationBuilder.DropIndex(
                name: "IX_recogidas_empresa_id",
                table: "recogidas");

            migrationBuilder.DropIndex(
                name: "IX_notificaciones_empresa_id",
                table: "notificaciones");

            migrationBuilder.DropIndex(
                name: "IX_ingresos_empresa_id",
                table: "ingresos");

            migrationBuilder.DropIndex(
                name: "IX_historial_estados_empresa_id",
                table: "historial_estados");

            migrationBuilder.DropIndex(
                name: "IX_evidencias_empresa_id",
                table: "evidencias");

            migrationBuilder.DropIndex(
                name: "IX_clientes_empresa_id",
                table: "clientes");

            migrationBuilder.DropIndex(
                name: "IX_cierres_caja_empresa_id",
                table: "cierres_caja");

            migrationBuilder.DropIndex(
                name: "IX_auditoria_logs_empresa_id",
                table: "auditoria_logs");

            migrationBuilder.DeleteData(
                table: "roles",
                keyColumn: "id",
                keyValue: 5);

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "ubicaciones");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "recogidas");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "notificaciones");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "ingresos");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "historial_estados");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "evidencias");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "clientes");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "cierres_caja");

            migrationBuilder.DropColumn(
                name: "empresa_id",
                table: "auditoria_logs");

            migrationBuilder.CreateTable(
                name: "empresas_clientes",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    activa = table.Column<bool>(type: "boolean", nullable: false),
                    ciclo_pago = table.Column<string>(type: "text", nullable: true),
                    correo_contacto = table.Column<string>(type: "text", nullable: true),
                    fecha_creacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    fecha_fin_membresia = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    fecha_inicio_membresia = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    monto_membresia = table.Column<decimal>(type: "numeric", nullable: true),
                    nombre_contacto = table.Column<string>(type: "text", nullable: true),
                    nombre_empresa = table.Column<string>(type: "text", nullable: false),
                    notas = table.Column<string>(type: "text", nullable: true),
                    telefono_contacto = table.Column<string>(type: "text", nullable: true),
                    ultimo_recordatorio_enviado = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    url_instalacion = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_empresas_clientes", x => x.id);
                });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "id",
                keyValue: 1,
                column: "descripcion",
                value: "Control total del sistema");

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "correo", "fecha_creacion", "nombre", "password_hash", "rol_id" },
                values: new object[] { "admin@loginova.com", new DateTime(2026, 6, 22, 0, 0, 0, 0, DateTimeKind.Utc), "Administrador", "pbkdf2$100000$TG9naW5vdmFTZWVkRml4ZQ==$uGONhA2zkb6zwPFQW3QzzJvOXsdfz88ogmVTbETi7Kw=", 1 });

            migrationBuilder.CreateIndex(
                name: "IX_empresas_clientes_activa",
                table: "empresas_clientes",
                column: "activa");

            migrationBuilder.CreateIndex(
                name: "IX_empresas_clientes_fecha_fin_membresia",
                table: "empresas_clientes",
                column: "fecha_fin_membresia");
        }
    }
}
