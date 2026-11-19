using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class BuyerCropsAndBlockedDates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Crops",
                table: "BuyerAreas",
                type: "nvarchar(700)",
                maxLength: 700,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SpaceBlockedDates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpaceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpaceBlockedDates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SpaceBlockedDates_Spaces_SpaceId",
                        column: x => x.SpaceId,
                        principalTable: "Spaces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SpaceBlockedDates_SpaceId_Date",
                table: "SpaceBlockedDates",
                columns: new[] { "SpaceId", "Date" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SpaceBlockedDates");

            migrationBuilder.DropColumn(
                name: "Crops",
                table: "BuyerAreas");
        }
    }
}
