using System;
using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ArrivalAndNearbyAlerts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ArrivalDistanceMeters",
                table: "Bookings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ArrivedAt",
                table: "Bookings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "NoShowAt",
                table: "Bookings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BuyerAreas",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Location = table.Column<Point>(type: "geography", nullable: false),
                    RadiusKm = table.Column<int>(type: "int", nullable: false),
                    AlertsOn = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BuyerAreas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BuyerAreas_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NearbyAlerts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BuyerUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BookingId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Kind = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NearbyAlerts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BuyerAreas_UserId",
                table: "BuyerAreas",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NearbyAlerts_BuyerUserId_BookingId_Kind",
                table: "NearbyAlerts",
                columns: new[] { "BuyerUserId", "BookingId", "Kind" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BuyerAreas");

            migrationBuilder.DropTable(
                name: "NearbyAlerts");

            migrationBuilder.DropColumn(
                name: "ArrivalDistanceMeters",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "ArrivedAt",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "NoShowAt",
                table: "Bookings");
        }
    }
}
