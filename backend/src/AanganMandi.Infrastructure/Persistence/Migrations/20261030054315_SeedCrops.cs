using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedCrops : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Crops",
                columns: new[] { "Id", "Category", "Code", "CreatedAt", "GrownInTelangana", "Icon", "IsDeleted", "NameEn", "NameHi", "NameTe", "SeasonMonths", "UpdatedAt", "YieldPerAcreKg" },
                values: new object[,]
                {
                    { new Guid("00000000-0000-0000-0001-000000000001"), "Vegetable", "TOMATO", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Tomato", "टमाटर", "టమాట", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000002"), "Vegetable", "BRINJAL", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Brinjal", "बैंगन", "వంకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000003"), "Vegetable", "OKRA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Okra", "भिंडी", "బెండకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000004"), "Vegetable", "ONION", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Onion", "प्याज", "ఉల్లిపాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000005"), "Vegetable", "GREEN_CHILLI", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Green chilli", "हरी मिर्च", "పచ్చిమిర్చి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000006"), "Vegetable", "BOTTLE_GOURD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Bottle gourd", "लौकी", "సొరకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000007"), "Leafy", "SPINACH", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Spinach", "पालक", "పాలకూర", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000008"), "Leafy", "CORIANDER", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Coriander", "धनिया", "కొత్తిమీర", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 2000m },
                    { new Guid("00000000-0000-0000-0001-000000000009"), "Fruit", "MANGO", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Mango", "आम", "మామిడి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000010"), "Fruit", "BANANA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Banana", "केला", "అరటి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 12000m }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000001"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000002"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000003"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000004"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000005"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000006"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000007"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000008"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000009"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000010"));
        }
    }
}
