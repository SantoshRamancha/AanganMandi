using AanganMandi.Domain.Identity;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Persistence;

/// <summary>Development only: adds the QA test accounts if they are missing. Never runs in Production.</summary>
public static class DevDataSeeder
{
    // +919000000004 is deliberately not seeded: it logs in as a brand-new user and sees the role screen.
    private static readonly (string Phone, string Name, string Lang, Role Role)[] TestUsers =
    [
        ("+919000000001", "Ramesh Reddy", "te", Role.Farmer),
        ("+919000000002", "Lakshmi Prasad", "en", Role.Host),
        ("+919000000003", "Anjali Sharma", "hi", Role.Buyer),
        // Ops admin: adds and removes verifiers, sees every farmer, reassigns.
        ("+919000000008", "Ops Admin", "en", Role.Admin),
        // Ops verifier: reviews the farmers assigned to them, and spaces.
        ("+919000000009", "Ops Verifier", "en", Role.Verifier),
    ];

    public static async Task SeedAsync(AppDbContext db, CancellationToken ct = default)
    {
        foreach (var (phone, name, lang, role) in TestUsers)
        {
            if (await db.Users.AnyAsync(u => u.Phone == phone, ct)) continue;
            db.Users.Add(new User
            {
                Phone = phone,
                Name = name,
                PreferredLanguage = lang,
                Roles = [new UserRole { Role = role }],
            });
        }
        await db.SaveChangesAsync(ct);
    }
}
