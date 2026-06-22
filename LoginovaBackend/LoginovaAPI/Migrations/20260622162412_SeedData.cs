using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LoginovaAPI.Migrations
{
    /// <inheritdoc />
    public partial class SeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 6, 22, 16, 24, 11, 742, DateTimeKind.Utc).AddTicks(1520), "pbkdf2$100000$K3mHljH8+IwT5X3Yzs6jZA==$Zk0KpLcM8F9cBVqWVqRx0cWX297/M2TNGgfxj3LX374=" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "usuarios",
                keyColumn: "id",
                keyValue: 1,
                columns: new[] { "fecha_creacion", "password_hash" },
                values: new object[] { new DateTime(2026, 6, 22, 16, 23, 2, 291, DateTimeKind.Utc).AddTicks(9659), "pbkdf2$100000$R076lQ86NwxlgrMqQPrnUQ==$FoHpW5OGVv+GHg8CqnIvWgkj7jTLto+E0k3l4BCsVsY=" });
        }
    }
}
