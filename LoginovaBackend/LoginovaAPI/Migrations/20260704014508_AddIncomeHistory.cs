using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddIncomeHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "forma_pago_ultima",
                table: "recogidas",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ingresos",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    recogida_id = table.Column<int>(type: "integer", nullable: false),
                    cliente_id = table.Column<int>(type: "integer", nullable: false),
                    responsable_usuario_id = table.Column<int>(type: "integer", nullable: false),
                    monto = table.Column<decimal>(type: "numeric", nullable: false),
                    forma_pago = table.Column<string>(type: "text", nullable: false),
                    fecha_ingreso = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ingresos", x => x.id);
                    table.ForeignKey(
                        name: "FK_ingresos_clientes_cliente_id",
                        column: x => x.cliente_id,
                        principalTable: "clientes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ingresos_recogidas_recogida_id",
                        column: x => x.recogida_id,
                        principalTable: "recogidas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ingresos_usuarios_responsable_usuario_id",
                        column: x => x.responsable_usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 7, 4, 1, 45, 8, 78, DateTimeKind.Utc).AddTicks(5873), "pbkdf2$100000$Mz5H5D/HLBMh8XJpehefgg==$oHa6c+5jiazyNL+1zbvpvCdxS1xssd0yi1JSLFwh3nU=" });

            migrationBuilder.CreateIndex(
                name: "IX_ingresos_cliente_id",
                table: "ingresos",
                column: "cliente_id");

            migrationBuilder.CreateIndex(
                name: "IX_ingresos_recogida_id",
                table: "ingresos",
                column: "recogida_id");

            migrationBuilder.CreateIndex(
                name: "IX_ingresos_responsable_usuario_id",
                table: "ingresos",
                column: "responsable_usuario_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ingresos");

            migrationBuilder.DropColumn(
                name: "forma_pago_ultima",
                table: "recogidas");

            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 7, 3, 20, 36, 15, 876, DateTimeKind.Utc).AddTicks(5251), "pbkdf2$100000$gTjzWiB+nhhcbAVqygYFZQ==$LImtHYh4ROglOXZtsMx80FP6/3LyE9ybQFXBGvJhcvo=" });
        }
    }
}
