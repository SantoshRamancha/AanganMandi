using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Identity;

public enum Role { Farmer, Host, Buyer, Verifier, Admin }

public class User : Entity
{
    public required string Phone { get; set; }
    public string? Name { get; set; }
    public string PreferredLanguage { get; set; } = "en";
    public string Status { get; set; } = "Active";
    public List<UserRole> Roles { get; set; } = [];
}

public class UserRole : Entity
{
    public Guid UserId { get; set; }
    public Role Role { get; set; }
}
