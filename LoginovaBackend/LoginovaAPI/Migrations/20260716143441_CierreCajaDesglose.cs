using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class CierreCajaDesglose : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_cierres_caja_operador_id_fecha",
                table: "cierres_caja");

            migrationBuilder.AddColumn<int>(
                name: "cierre_caja_id",
                table: "ingresos",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "generado_automaticamente",
                table: "cierres_caja",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "monto_efectivo",
                table: "cierres_caja",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "monto_transferencia",
                table: "cierres_caja",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.InsertData(
                table: "permisos",
                columns: new[] { "id", "descripcion", "nombre" },
                values: new object[] { 15, "Cerrar la caja de un operador o subadministrador", "cerrar_caja" });

            // No se reescribe usuarios.id=1 aquí a propósito: el seed ahora es
            // determinista (ver AppDbContext), pero la fila real en cada base
            // de datos desplegada ya tiene su propio correo/contraseña reales
            // (fueron cambiados tras el primer despliegue) y no deben pisarse.

            migrationBuilder.CreateIndex(
                name: "IX_ingresos_cierre_caja_id",
                table: "ingresos",
                column: "cierre_caja_id");

            migrationBuilder.CreateIndex(
                name: "IX_cierres_caja_operador_id_fecha",
                table: "cierres_caja",
                columns: new[] { "operador_id", "fecha" });

            migrationBuilder.AddForeignKey(
                name: "FK_ingresos_cierres_caja_cierre_caja_id",
                table: "ingresos",
                column: "cierre_caja_id",
                principalTable: "cierres_caja",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ingresos_cierres_caja_cierre_caja_id",
                table: "ingresos");

            migrationBuilder.DropIndex(
                name: "IX_ingresos_cierre_caja_id",
                table: "ingresos");

            migrationBuilder.DropIndex(
                name: "IX_cierres_caja_operador_id_fecha",
                table: "cierres_caja");

            migrationBuilder.DeleteData(
                table: "permisos",
                keyColumn: "id",
                keyValue: 15);

            migrationBuilder.DropColumn(
                name: "cierre_caja_id",
                table: "ingresos");

            migrationBuilder.DropColumn(
                name: "generado_automaticamente",
                table: "cierres_caja");

            migrationBuilder.DropColumn(
                name: "monto_efectivo",
                table: "cierres_caja");

            migrationBuilder.DropColumn(
                name: "monto_transferencia",
                table: "cierres_caja");

            migrationBuilder.CreateIndex(
                name: "IX_cierres_caja_operador_id_fecha",
                table: "cierres_caja",
                columns: new[] { "operador_id", "fecha" },
                unique: true);
        }
    }
}
