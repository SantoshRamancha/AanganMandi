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
            e.Property(p => p.CropCode).HasMaxLength(32);
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
