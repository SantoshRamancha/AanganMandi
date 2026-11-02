using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Identity;

/// <summary>30-day refresh token, stored only as a SHA-256 hash and rotated on every use.</summary>
public class RefreshToken : Entity
{
    public Guid UserId { get; set; }
    public required string TokenHash { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}
