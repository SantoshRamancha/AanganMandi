using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RatingsAndNoShows : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Ratings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BookingId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpaceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RaterUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RatedUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    By = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: false),
                    Stars = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Ratings", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_FarmerUserId_NoShowAt",
                table: "Bookings",
                columns: new[] { "FarmerUserId", "NoShowAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Ratings_BookingId_By",
                table: "Ratings",
                columns: new[] { "BookingId", "By" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Ratings_RatedUserId_By",
                table: "Ratings",
                columns: new[] { "RatedUserId", "By" });

            migrationBuilder.CreateIndex(
                name: "IX_Ratings_SpaceId",
                table: "Ratings",
                column: "SpaceId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Ratings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_FarmerUserId_NoShowAt",
                table: "Bookings");
        }
    }
}
