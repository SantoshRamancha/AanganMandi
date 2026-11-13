using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class BookingShareCode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ShareCode",
                table: "Bookings",
                type: "nvarchar(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_ShareCode",
                table: "Bookings",
                column: "ShareCode",
                unique: true,
                filter: "[ShareCode] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bookings_ShareCode",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "ShareCode",
                table: "Bookings");
        }
    }
}
