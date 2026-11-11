using AanganMandi.Domain.Common;
using NetTopologySuite.Geometries;

namespace AanganMandi.Domain.Spaces;

public enum SpaceType { Driveway, Courtyard, OpenArea, CommercialFrontage }

public enum VehicleType { TwoWheeler, Auto, MiniTruck, Tractor }

[Flags]
public enum Amenities
{
    None = 0,
    Water = 1,
    Shade = 2,
    PowerPoint = 4,
    BuyerParking = 8,
    LoadingAccess = 16,
    Toilet = 32,
}

public enum SpaceStatus { Draft, PendingReview, Live, Rejected }

/// <summary>
/// A host's space (FR-1.2–1.8). Goes live only after an admin checks photos, location and right-to-use proof.
/// Deleting a space only sets IsDeleted (a query filter hides it), so past bookings can still show its name.
/// </summary>
public class Space : Entity
{
    public Guid HostUserId { get; set; }
    public required string Title { get; set; }
    public SpaceType Type { get; set; }
    /// <summary>Exact address: shown only to the farmer of an approved booking (FR-1.9).</summary>
    public required string Address { get; set; }
    public required string Locality { get; set; }
    public required Point Location { get; set; }
    public int AreaSqFt { get; set; }
    public string MaxStallSize { get; set; } = "10x10 ft";
    public VehicleType MaxVehicle { get; set; }
    public Amenities Amenities { get; set; }
    public bool IsFree { get; set; }
    public decimal Fee { get; set; }
    public string? Rules { get; set; }
    /// <summary>Weekly availability, e.g. "Sat,Sun", with one daily window (2–6 hours).</summary>
    public required string AvailableDays { get; set; }
    public TimeOnly OpenFrom { get; set; }
    public TimeOnly OpenTo { get; set; }
    public SpaceStatus Status { get; set; } = SpaceStatus.Draft;
    public string? RejectionReason { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public List<SpacePhoto> Photos { get; set; } = [];
}

public class SpacePhoto : Entity
{
    public Guid SpaceId { get; set; }
    public required string FilePath { get; set; }
    /// <summary>Ownership/rental document or society NOC (FR-1.1). Private, never shown to buyers.</summary>
    public bool IsRightToUseProof { get; set; }
}
