using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Master;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    // Starter crop master data (Telangana vegetables). Yields are rough pilot placeholders for ops to tune.
    private static readonly DateTime SeedAt = new(2026, 10, 30, 0, 0, 0, DateTimeKind.Utc);
    private static Crop C(int n, string code, string en, string te, string hi, string cat, decimal yield) => new()
    {
        Id = Guid.Parse($"00000000-0000-0000-0001-{n:D12}"), CreatedAt = SeedAt, UpdatedAt = SeedAt,
        Code = code, NameEn = en, NameTe = te, NameHi = hi, Category = cat, YieldPerAcreKg = yield,
    };
    private static readonly Crop[] SeedCrops =
    [
        C(1, "TOMATO", "Tomato", "టమాట", "टमाटर", "Vegetable", 10000),
        C(2, "BRINJAL", "Brinjal", "వంకాయ", "बैंगन", "Vegetable", 8000),
        C(3, "OKRA", "Okra", "బెండకాయ", "भिंडी", "Vegetable", 4000),
        C(4, "ONION", "Onion", "ఉల్లిపాయ", "प्याज", "Vegetable", 8000),
        C(5, "GREEN_CHILLI", "Green chilli", "పచ్చిమిర్చి", "हरी मिर्च", "Vegetable", 3000),
        C(6, "BOTTLE_GOURD", "Bottle gourd", "సొరకాయ", "लौकी", "Vegetable", 10000),
        C(7, "SPINACH", "Spinach", "పాలకూర", "पालक", "Leafy", 4000),
        C(8, "CORIANDER", "Coriander", "కొత్తిమీర", "धनिया", "Leafy", 2000),
        C(9, "MANGO", "Mango", "మామిడి", "आम", "Fruit", 3000),
        C(10, "BANANA", "Banana", "అరటి", "केला", "Fruit", 12000),
        // Vegetables
        C(11, "POTATO", "Potato", "బంగాళాదుంప", "आलू", "Vegetable", 10000),
        C(12, "CABBAGE", "Cabbage", "క్యాబేజీ", "पत्ता गोभी", "Vegetable", 12000),
        C(13, "CAULIFLOWER", "Cauliflower", "కాలీఫ్లవర్", "फूलगोभी", "Vegetable", 8000),
        C(14, "CARROT", "Carrot", "క్యారెట్", "गाजर", "Vegetable", 10000),
        C(15, "BEETROOT", "Beetroot", "బీట్‌రూట్", "चुकंदर", "Vegetable", 10000),
        C(16, "RADISH", "Radish", "ముల్లంగి", "मूली", "Vegetable", 8000),
        C(17, "CUCUMBER", "Cucumber", "దోసకాయ", "खीरा", "Vegetable", 8000),
        C(18, "BITTER_GOURD", "Bitter gourd", "కాకరకాయ", "करेला", "Vegetable", 5000),
        C(19, "RIDGE_GOURD", "Ridge gourd", "బీరకాయ", "तुरई", "Vegetable", 6000),
        C(20, "SNAKE_GOURD", "Snake gourd", "పొట్లకాయ", "चिचिंडा", "Vegetable", 6000),
        C(21, "PUMPKIN", "Pumpkin", "గుమ్మడికాయ", "कद्दू", "Vegetable", 10000),
        C(22, "IVY_GOURD", "Ivy gourd", "దొండకాయ", "कुंदरू", "Vegetable", 5000),
        C(23, "DRUMSTICK", "Drumstick", "మునగకాయ", "सहजन", "Vegetable", 4000),
        C(24, "FRENCH_BEANS", "French beans", "బీన్స్", "फ्रेंच बीन्स", "Vegetable", 4000),
        C(25, "CLUSTER_BEANS", "Cluster beans", "గోరుచిక్కుడు", "ग्वार फली", "Vegetable", 3000),
        C(26, "BROAD_BEANS", "Broad beans", "చిక్కుడుకాయ", "सेम", "Vegetable", 4000),
        C(27, "CAPSICUM", "Capsicum", "క్యాప్సికమ్", "शिमला मिर्च", "Vegetable", 6000),
        C(28, "SWEET_POTATO", "Sweet potato", "చిలగడదుంప", "शकरकंद", "Vegetable", 8000),
        C(29, "GARLIC", "Garlic", "వెల్లుల్లి", "लहसुन", "Vegetable", 3000),
        C(30, "GINGER", "Ginger", "అల్లం", "अदरक", "Vegetable", 6000),
        C(31, "SWEET_CORN", "Sweet corn", "స్వీట్ కార్న్", "स्वीट कॉर्न", "Vegetable", 5000),
        // Leafy greens
        C(32, "METHI", "Fenugreek leaves", "మెంతికూర", "मेथी", "Leafy", 2500),
        C(33, "GONGURA", "Gongura", "గోంగూర", "गोंगूरा", "Leafy", 3000),
        C(34, "AMARANTH", "Amaranth leaves", "తోటకూర", "चौलाई", "Leafy", 3000),
        C(35, "MINT", "Mint", "పుదీనా", "पुदीना", "Leafy", 3000),
        C(36, "CURRY_LEAVES", "Curry leaves", "కరివేపాకు", "करी पत्ता", "Leafy", 2000),
        C(37, "SPRING_ONION", "Spring onion", "ఉల్లికాడలు", "हरा प्याज", "Leafy", 3000),
        // Fruits
        C(38, "PAPAYA", "Papaya", "బొప్పాయి", "पपीता", "Fruit", 15000),
        C(39, "GUAVA", "Guava", "జామ", "अमरूद", "Fruit", 6000),
        C(40, "POMEGRANATE", "Pomegranate", "దానిమ్మ", "अनार", "Fruit", 4000),
        C(41, "SWEET_LIME", "Sweet lime", "బత్తాయి", "मौसंबी", "Fruit", 6000),
        C(42, "LEMON", "Lemon", "నిమ్మకాయ", "नींबू", "Fruit", 4000),
        C(43, "WATERMELON", "Watermelon", "పుచ్చకాయ", "तरबूज", "Fruit", 10000),
        C(44, "MUSKMELON", "Muskmelon", "కర్బూజ", "खरबूजा", "Fruit", 6000),
        C(45, "SAPOTA", "Sapota", "సపోటా", "चीकू", "Fruit", 5000),
        C(46, "CUSTARD_APPLE", "Custard apple", "సీతాఫలం", "शरीफा", "Fruit", 3000),
        C(47, "COCONUT", "Coconut", "కొబ్బరికాయ", "नारियल", "Fruit", 4000),
        C(48, "GRAPES", "Grapes", "ద్రాక్ష", "अंगूर", "Fruit", 8000),
        // Grains, millets, pulses, oilseeds
        C(49, "RICE", "Rice", "బియ్యం", "चावल", "Grain", 2500),
        C(50, "MAIZE", "Maize", "మొక్కజొన్న", "मक्का", "Grain", 2500),
        C(51, "JOWAR", "Jowar", "జొన్నలు", "ज्वार", "Grain", 1200),
        C(52, "FOXTAIL_MILLET", "Foxtail millet", "కొర్రలు", "कंगनी", "Grain", 800),
        C(53, "RED_GRAM", "Red gram (toor dal)", "కందులు", "अरहर (तूर)", "Pulse", 600),
        C(54, "GREEN_GRAM", "Green gram (moong)", "పెసలు", "मूंग", "Pulse", 500),
        C(55, "BENGAL_GRAM", "Bengal gram (chana)", "శనగలు", "चना", "Pulse", 700),
        C(56, "GROUNDNUT", "Groundnut", "వేరుశనగ", "मूंगफली", "Oilseed", 1000),
        // Spices and flowers
        C(57, "TURMERIC", "Turmeric", "పసుపు", "हल्दी", "Spice", 8000),
        C(58, "DRY_CHILLI", "Dry red chilli", "ఎండు మిర్చి", "सूखी लाल मिर्च", "Spice", 1500),
        C(59, "MARIGOLD", "Marigold flowers", "బంతి పూలు", "गेंदा फूल", "Flower", 4000),
        C(60, "JASMINE", "Jasmine flowers", "మల్లె పూలు", "चमेली फूल", "Flower", 1500),
    ];

    public DbSet<User> Users => Set<User>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Crop> Crops => Set<Crop>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<FarmerProfile> FarmerProfiles => Set<FarmerProfile>();
    public DbSet<FarmerCrop> FarmerCrops => Set<FarmerCrop>();
    public DbSet<FarmPlot> FarmPlots => Set<FarmPlot>();
    public DbSet<VerificationDocument> VerificationDocuments => Set<VerificationDocument>();
    public DbSet<Space> Spaces => Set<Space>();
    public DbSet<SpacePhoto> SpacePhotos => Set<SpacePhoto>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripProduce> TripProduce => Set<TripProduce>();
    public DbSet<Booking> Bookings => Set<Booking>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<User>(e =>
        {
            e.HasIndex(u => u.Phone).IsUnique();
            e.Property(u => u.Phone).HasMaxLength(15);
            e.Property(u => u.PreferredLanguage).HasMaxLength(2);
            e.HasMany(u => u.Roles).WithOne().HasForeignKey(r => r.UserId);
            e.HasQueryFilter(u => !u.IsDeleted);
        });
        b.Entity<UserRole>().Property(r => r.Role).HasConversion<string>().HasMaxLength(16);
        b.Entity<Crop>(e =>
        {
            e.HasIndex(c => c.Code).IsUnique();
            e.Property(c => c.YieldPerAcreKg).HasPrecision(10, 2);
            e.HasData(SeedCrops);
        });

        b.Entity<RefreshToken>(e =>
        {
            e.HasIndex(t => t.TokenHash).IsUnique();
            e.Property(t => t.TokenHash).HasMaxLength(64);
        });
        b.Entity<FarmerProfile>(e =>
        {
            e.HasIndex(f => f.UserId).IsUnique();
            e.HasIndex(f => f.Status);
            e.HasIndex(f => new { f.AssignedVerifierId, f.Status });
            e.Property(f => f.Status).HasConversion<string>().HasMaxLength(16);
            e.Property(f => f.FarmSizeAcres).HasPrecision(8, 2);
            e.Property(f => f.ProduceSource).HasConversion<string>().HasMaxLength(24);
            e.Property(f => f.EvidenceType).HasConversion<string>().HasMaxLength(24);
            e.Property(f => f.EvidenceDetails).HasMaxLength(200);
            e.HasOne<User>().WithMany().HasForeignKey(f => f.AssignedVerifierId).OnDelete(DeleteBehavior.NoAction);
            e.HasMany(f => f.Crops).WithOne().HasForeignKey(c => c.FarmerId);
            e.HasMany(f => f.Plots).WithOne().HasForeignKey(p => p.FarmerId);
        });
        b.Entity<FarmerCrop>().HasIndex(c => new { c.FarmerId, c.CropCode }).IsUnique();
        b.Entity<FarmPlot>(e =>
        {
            e.Property(p => p.ExtentAcres).HasPrecision(8, 2);
            e.Property(p => p.OwnershipType).HasConversion<string>().HasMaxLength(16);
            e.Property(p => p.Location).HasColumnType("geography");
            e.HasMany(p => p.Crops).WithOne().HasForeignKey(c => c.PlotId);
        });
        b.Entity<VerificationDocument>(e =>
        {
            e.HasIndex(d => new { d.OwnerUserId, d.Type });
            e.Property(d => d.Type).HasConversion<string>().HasMaxLength(24);
            e.Property(d => d.CapturedAt).HasColumnType("geography");
        });
        b.Entity<Space>(e =>
        {
            e.HasIndex(s => s.HostUserId);
            e.HasIndex(s => s.Status);
            e.Property(s => s.Type).HasConversion<string>().HasMaxLength(24);
            e.Property(s => s.MaxVehicle).HasConversion<string>().HasMaxLength(16);
            e.Property(s => s.Status).HasConversion<string>().HasMaxLength(16);
            e.Property(s => s.Fee).HasPrecision(10, 2);
            e.Property(s => s.Location).HasColumnType("geography");
            e.HasMany(s => s.Photos).WithOne().HasForeignKey(p => p.SpaceId);
        });
        b.Entity<Trip>(e =>
        {
            e.HasIndex(t => new { t.FarmerUserId, t.Date });
            e.Property(t => t.Vehicle).HasConversion<string>().HasMaxLength(16);
            e.Property(t => t.Status).HasConversion<string>().HasMaxLength(16);
            e.Property(t => t.PreferredArea).HasMaxLength(80);
            e.Property(t => t.Notes).HasMaxLength(200);
            e.HasOne<User>().WithMany().HasForeignKey(t => t.FarmerUserId).OnDelete(DeleteBehavior.NoAction);
            e.HasMany(t => t.Produce).WithOne().HasForeignKey(p => p.TripId);
        });
        b.Entity<TripProduce>(e =>
        {
            e.Property(p => p.CropCode).HasMaxLength(64);
            e.Property(p => p.QuantityKg).HasPrecision(10, 2);
            e.Property(p => p.PricePerKg).HasPrecision(10, 2);
        });
        b.Entity<Booking>(e =>
        {
            e.HasIndex(x => new { x.SpaceId, x.Date, x.Status });
            e.HasIndex(x => new { x.HostUserId, x.Status });
            e.HasIndex(x => x.TripId);
            // At most one confirmed farmer per space and day, even if two hosts' clicks race.
            e.HasIndex(x => new { x.SpaceId, x.Date }).IsUnique().HasFilter("[Status] = 'Accepted'")
                .HasDatabaseName("IX_Bookings_OneAcceptedPerSpaceDay");
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(16);
            e.Property(x => x.Fee).HasPrecision(10, 2);
            e.Property(x => x.Message).HasMaxLength(200);
            e.Property(x => x.Reason).HasMaxLength(200);
            e.Property(x => x.CancelledBy).HasMaxLength(8);
            e.HasOne<Trip>().WithMany().HasForeignKey(x => x.TripId).OnDelete(DeleteBehavior.NoAction);
            e.HasOne<Space>().WithMany().HasForeignKey(x => x.SpaceId).OnDelete(DeleteBehavior.NoAction);
        });
    }
}
