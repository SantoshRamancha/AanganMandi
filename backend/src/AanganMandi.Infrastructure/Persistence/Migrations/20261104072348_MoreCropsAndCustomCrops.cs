using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AanganMandi.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MoreCropsAndCustomCrops : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "CropCode",
                table: "TripProduce",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(32)",
                oldMaxLength: 32);

            migrationBuilder.InsertData(
                table: "Crops",
                columns: new[] { "Id", "Category", "Code", "CreatedAt", "GrownInTelangana", "Icon", "IsDeleted", "NameEn", "NameHi", "NameTe", "SeasonMonths", "UpdatedAt", "YieldPerAcreKg" },
                values: new object[,]
                {
                    { new Guid("00000000-0000-0000-0001-000000000011"), "Vegetable", "POTATO", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Potato", "आलू", "బంగాళాదుంప", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000012"), "Vegetable", "CABBAGE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Cabbage", "पत्ता गोभी", "క్యాబేజీ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 12000m },
                    { new Guid("00000000-0000-0000-0001-000000000013"), "Vegetable", "CAULIFLOWER", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Cauliflower", "फूलगोभी", "కాలీఫ్లవర్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000014"), "Vegetable", "CARROT", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Carrot", "गाजर", "క్యారెట్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000015"), "Vegetable", "BEETROOT", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Beetroot", "चुकंदर", "బీట్‌రూట్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000016"), "Vegetable", "RADISH", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Radish", "मूली", "ముల్లంగి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000017"), "Vegetable", "CUCUMBER", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Cucumber", "खीरा", "దోసకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000018"), "Vegetable", "BITTER_GOURD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Bitter gourd", "करेला", "కాకరకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 5000m },
                    { new Guid("00000000-0000-0000-0001-000000000019"), "Vegetable", "RIDGE_GOURD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Ridge gourd", "तुरई", "బీరకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000020"), "Vegetable", "SNAKE_GOURD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Snake gourd", "चिचिंडा", "పొట్లకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000021"), "Vegetable", "PUMPKIN", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Pumpkin", "कद्दू", "గుమ్మడికాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000022"), "Vegetable", "IVY_GOURD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Ivy gourd", "कुंदरू", "దొండకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 5000m },
                    { new Guid("00000000-0000-0000-0001-000000000023"), "Vegetable", "DRUMSTICK", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Drumstick", "सहजन", "మునగకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000024"), "Vegetable", "FRENCH_BEANS", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "French beans", "फ्रेंच बीन्स", "బీన్స్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000025"), "Vegetable", "CLUSTER_BEANS", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Cluster beans", "ग्वार फली", "గోరుచిక్కుడు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000026"), "Vegetable", "BROAD_BEANS", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Broad beans", "सेम", "చిక్కుడుకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000027"), "Vegetable", "CAPSICUM", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Capsicum", "शिमला मिर्च", "క్యాప్సికమ్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000028"), "Vegetable", "SWEET_POTATO", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Sweet potato", "शकरकंद", "చిలగడదుంప", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000029"), "Vegetable", "GARLIC", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Garlic", "लहसुन", "వెల్లుల్లి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000030"), "Vegetable", "GINGER", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Ginger", "अदरक", "అల్లం", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000031"), "Vegetable", "SWEET_CORN", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Sweet corn", "स्वीट कॉर्न", "స్వీట్ కార్న్", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 5000m },
                    { new Guid("00000000-0000-0000-0001-000000000032"), "Leafy", "METHI", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Fenugreek leaves", "मेथी", "మెంతికూర", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 2500m },
                    { new Guid("00000000-0000-0000-0001-000000000033"), "Leafy", "GONGURA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Gongura", "गोंगूरा", "గోంగూర", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000034"), "Leafy", "AMARANTH", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Amaranth leaves", "चौलाई", "తోటకూర", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000035"), "Leafy", "MINT", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Mint", "पुदीना", "పుదీనా", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000036"), "Leafy", "CURRY_LEAVES", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Curry leaves", "करी पत्ता", "కరివేపాకు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 2000m },
                    { new Guid("00000000-0000-0000-0001-000000000037"), "Leafy", "SPRING_ONION", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Spring onion", "हरा प्याज", "ఉల్లికాడలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000038"), "Fruit", "PAPAYA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Papaya", "पपीता", "బొప్పాయి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 15000m },
                    { new Guid("00000000-0000-0000-0001-000000000039"), "Fruit", "GUAVA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Guava", "अमरूद", "జామ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000040"), "Fruit", "POMEGRANATE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Pomegranate", "अनार", "దానిమ్మ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000041"), "Fruit", "SWEET_LIME", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Sweet lime", "मौसंबी", "బత్తాయి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000042"), "Fruit", "LEMON", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Lemon", "नींबू", "నిమ్మకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000043"), "Fruit", "WATERMELON", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Watermelon", "तरबूज", "పుచ్చకాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10000m },
                    { new Guid("00000000-0000-0000-0001-000000000044"), "Fruit", "MUSKMELON", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Muskmelon", "खरबूजा", "కర్బూజ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 6000m },
                    { new Guid("00000000-0000-0000-0001-000000000045"), "Fruit", "SAPOTA", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Sapota", "चीकू", "సపోటా", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 5000m },
                    { new Guid("00000000-0000-0000-0001-000000000046"), "Fruit", "CUSTARD_APPLE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Custard apple", "शरीफा", "సీతాఫలం", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 3000m },
                    { new Guid("00000000-0000-0000-0001-000000000047"), "Fruit", "COCONUT", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Coconut", "नारियल", "కొబ్బరికాయ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000048"), "Fruit", "GRAPES", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Grapes", "अंगूर", "ద్రాక్ష", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000049"), "Grain", "RICE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Rice", "चावल", "బియ్యం", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 2500m },
                    { new Guid("00000000-0000-0000-0001-000000000050"), "Grain", "MAIZE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Maize", "मक्का", "మొక్కజొన్న", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 2500m },
                    { new Guid("00000000-0000-0000-0001-000000000051"), "Grain", "JOWAR", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Jowar", "ज्वार", "జొన్నలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 1200m },
                    { new Guid("00000000-0000-0000-0001-000000000052"), "Grain", "FOXTAIL_MILLET", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Foxtail millet", "कंगनी", "కొర్రలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 800m },
                    { new Guid("00000000-0000-0000-0001-000000000053"), "Pulse", "RED_GRAM", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Red gram (toor dal)", "अरहर (तूर)", "కందులు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 600m },
                    { new Guid("00000000-0000-0000-0001-000000000054"), "Pulse", "GREEN_GRAM", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Green gram (moong)", "मूंग", "పెసలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 500m },
                    { new Guid("00000000-0000-0000-0001-000000000055"), "Pulse", "BENGAL_GRAM", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Bengal gram (chana)", "चना", "శనగలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 700m },
                    { new Guid("00000000-0000-0000-0001-000000000056"), "Oilseed", "GROUNDNUT", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Groundnut", "मूंगफली", "వేరుశనగ", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 1000m },
                    { new Guid("00000000-0000-0000-0001-000000000057"), "Spice", "TURMERIC", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Turmeric", "हल्दी", "పసుపు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 8000m },
                    { new Guid("00000000-0000-0000-0001-000000000058"), "Spice", "DRY_CHILLI", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Dry red chilli", "सूखी लाल मिर्च", "ఎండు మిర్చి", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 1500m },
                    { new Guid("00000000-0000-0000-0001-000000000059"), "Flower", "MARIGOLD", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Marigold flowers", "गेंदा फूल", "బంతి పూలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 4000m },
                    { new Guid("00000000-0000-0000-0001-000000000060"), "Flower", "JASMINE", new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), true, null, false, "Jasmine flowers", "चमेली फूल", "మల్లె పూలు", null, new DateTime(2026, 10, 30, 0, 0, 0, 0, DateTimeKind.Utc), 1500m }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000011"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000012"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000013"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000014"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000015"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000016"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000017"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000018"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000019"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000020"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000021"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000022"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000023"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000024"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000025"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000026"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000027"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000028"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000029"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000030"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000031"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000032"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000033"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000034"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000035"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000036"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000037"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000038"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000039"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000040"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000041"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000042"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000043"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000044"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000045"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000046"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000047"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000048"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000049"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000050"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000051"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000052"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000053"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000054"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000055"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000056"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000057"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000058"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000059"));

            migrationBuilder.DeleteData(
                table: "Crops",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0001-000000000060"));

            migrationBuilder.AlterColumn<string>(
                name: "CropCode",
                table: "TripProduce",
                type: "nvarchar(32)",
                maxLength: 32,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(64)",
                oldMaxLength: 64);
        }
    }
}
