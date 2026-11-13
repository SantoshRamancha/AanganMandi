using AanganMandi.Domain.Common;
using NetTopologySuite.Geometries;

namespace AanganMandi.Domain.Buyers;

/// <summary>
/// Where a buyer wants to hear about farmers selling nearby: a point they saved (usually home) and a radius.
/// One per buyer. Without it the buyer sees no nearby list and gets no alerts.
/// </summary>
public class BuyerArea : Entity
{
    public Guid UserId { get; set; }
    /// <summary>SRID 4326, stored as geography so distances are in metres.</summary>
    public required Point Location { get; set; }
    public int RadiusKm { get; set; } = 2;
    /// <summary>Email alerts (day before, selling now). The in-app list shows either way.</summary>
    public bool AlertsOn { get; set; } = true;

    /// <summary>The radii a buyer can pick, in km.</summary>
    public static readonly int[] Radii = [1, 2, 5];
}

public enum NearbyAlertKind { DayBefore, SellingNow }

/// <summary>One alert sent to one buyer about one booking, so a re-run or a second check-in never sends it twice.</summary>
public class NearbyAlert : Entity
{
    public Guid BuyerUserId { get; set; }
    public Guid BookingId { get; set; }
    public NearbyAlertKind Kind { get; set; }
}
