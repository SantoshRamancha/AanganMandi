using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MvpFarmerVerificationAndVerifiers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AadhaarLast4",
                table: "FarmerProfiles");

            migrationBuilder.AddColumn<DateTime>(
                name: "AssignedAt",
                table: "FarmerProfiles",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedVerifierId",
                table: "FarmerProfiles",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EvidenceDetails",
                table: "FarmerProfiles",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EvidenceType",
                table: "FarmerProfiles",
                type: "nvarchar(24)",
                maxLength: 24,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "FarmSizeAcres",
                table: "FarmerProfiles",
                type: "decimal(8,2)",
                precision: 8,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProduceSource",
                table: "FarmerProfiles",
                type: "nvarchar(24)",
                maxLength: 24,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "FarmerCrops",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FarmerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CropCode = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FarmerCrops", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FarmerCrops_FarmerProfiles_FarmerId",
                        column: x => x.FarmerId,
                        principalTable: "FarmerProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FarmerProfiles_AssignedVerifierId_Status",
                table: "FarmerProfiles",
                columns: new[] { "AssignedVerifierId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_FarmerCrops_FarmerId_CropCode",
                table: "FarmerCrops",
                columns: new[] { "FarmerId", "CropCode" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_FarmerProfiles_Users_AssignedVerifierId",
                table: "FarmerProfiles",
                column: "AssignedVerifierId",
                principalTable: "Users",
                principalColumn: "Id");

            // Farmers from the earlier flow keep the crops they listed on their plot.
            migrationBuilder.Sql("""
                INSERT INTO FarmerCrops (Id, FarmerId, CropCode, CreatedAt, UpdatedAt, IsDeleted)
                SELECT NEWID(), x.FarmerId, x.CropCode, SYSUTCDATETIME(), SYSUTCDATETIME(), 0
                FROM (SELECT DISTINCT p.FarmerId, c.CropCode FROM PlotCrop c JOIN FarmPlots p ON p.Id = c.PlotId) x
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FarmerProfiles_Users_AssignedVerifierId",
                table: "FarmerProfiles");

            migrationBuilder.DropTable(
                name: "FarmerCrops");

            migrationBuilder.DropIndex(
                name: "IX_FarmerProfiles_AssignedVerifierId_Status",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "AssignedAt",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "AssignedVerifierId",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "EvidenceDetails",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "EvidenceType",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "FarmSizeAcres",
                table: "FarmerProfiles");

            migrationBuilder.DropColumn(
                name: "ProduceSource",
                table: "FarmerProfiles");

            migrationBuilder.AddColumn<string>(
                name: "AadhaarLast4",
                table: "FarmerProfiles",
                type: "nchar(4)",
                fixedLength: true,
                maxLength: 4,
                nullable: true);
        }
    }
}
