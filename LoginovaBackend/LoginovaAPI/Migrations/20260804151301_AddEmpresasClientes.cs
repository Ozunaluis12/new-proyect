using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddEmpresasClientes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "empresas_clientes",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    nombre_empresa = table.Column<string>(type: "text", nullable: false),
                    nombre_contacto = table.Column<string>(type: "text", nullable: true),
                    telefono_contacto = table.Column<string>(type: "text", nullable: true),
                    correo_contacto = table.Column<string>(type: "text", nullable: true),
                    url_instalacion = table.Column<string>(type: "text", nullable: true),
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
                    table.PrimaryKey("PK_empresas_clientes", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_empresas_clientes_activa",
                table: "empresas_clientes",
                column: "activa");

            migrationBuilder.CreateIndex(
                name: "IX_empresas_clientes_fecha_fin_membresia",
                table: "empresas_clientes",
                column: "fecha_fin_membresia");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "empresas_clientes");
        }
    }
}
