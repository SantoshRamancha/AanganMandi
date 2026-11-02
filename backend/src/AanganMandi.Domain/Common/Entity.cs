namespace AanganMandi.Domain.Common;

/// <summary>Base for every table (spec Section 5): sequential GUID id, UTC audit stamps, soft delete.</summary>
public abstract class Entity
{
    public Guid Id { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; }
}
