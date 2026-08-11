using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AgregaPagosMembresiaYConfiguracionSoporte : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "configuracion_soporte",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    plantilla_recordatorio_vigente = table.Column<string>(type: "text", nullable: false),
                    plantilla_recordatorio_vencida = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_configuracion_soporte", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "pagos_membresia",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    empresa_id = table.Column<int>(type: "integer", nullable: false),
                    monto = table.Column<decimal>(type: "numeric", nullable: false),
                    ciclo_pago = table.Column<string>(type: "text", nullable: true),
                    fecha_pago = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    periodo_desde = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    periodo_hasta = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    notas = table.Column<string>(type: "text", nullable: true),
                    registrado_por_nombre = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_pagos_membresia", x => x.id);
                    table.ForeignKey(
                        name: "FK_pagos_membresia_empresas_empresa_id",
                        column: x => x.empresa_id,
                        principalTable: "empresas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "configuracion_soporte",
                columns: new[] { "id", "plantilla_recordatorio_vencida", "plantilla_recordatorio_vigente" },
                values: new object[] { 1, "Hola {contacto}, te escribimos de Loginova: la membresía de {empresa} venció el {fecha}. ¿Deseas renovarla para seguir usando el sistema sin interrupciones?", "Hola {contacto}, te escribimos de Loginova: la membresía de {empresa} vence el {fecha}. ¿Deseas que gestionemos la renovación?" });

            migrationBuilder.CreateIndex(
                name: "IX_pagos_membresia_empresa_id",
                table: "pagos_membresia",
                column: "empresa_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "configuracion_soporte");

            migrationBuilder.DropTable(
                name: "pagos_membresia");
        }
    }
}
