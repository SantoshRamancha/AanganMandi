using AanganMandi.Domain.Common;
using AanganMandi.Domain.Spaces;

namespace AanganMandi.Domain.Trips;

/// <summary>Planned or cancelled; a planned trip whose date has passed is shown as completed.</summary>
public enum TripStatus { Planned, Cancelled }

/// <summary>
/// Requested → Accepted or Declined (by the host); Requested or Accepted → Cancelled (by either side).
/// </summary>
public enum BookingStatus { Requested, Accepted, Declined, Cancelled }

/// <summary>A verified farmer's selling day in the city: when, in what vehicle, with which produce.</summary>
public class Trip : Entity
{
    public Guid FarmerUserId { get; set; }
    public DateOnly Date { get; set; }
    public VehicleType Vehicle { get; set; }
    /// <summary>Where in the city the farmer would like to sell, e.g. "Ameerpet". Optional; filters the space search.</summary>
    public string? PreferredArea { get; set; }
    public string? Notes { get; set; }
    public TripStatus Status { get; set; } = TripStatus.Planned;
    public List<TripProduce> Produce { get; set; } = [];
}

/// <summary>One crop the farmer brings; quantity and price are optional estimates shown to the host (and later buyers).</summary>
public class TripProduce : Entity
{
    public Guid TripId { get; set; }
    public required string CropCode { get; set; }
    public decimal? QuantityKg { get; set; }
    public decimal? PricePerKg { get; set; }
}

/// <summary>
/// A farmer's request for a space's daily slot on the trip date. The slot hours and fee are copied at request time,
/// so a later edit of the space does not change an agreed booking. The exact address and both phone numbers are
/// shared only once the host accepts (FR-1.9).
/// </summary>
public class Booking : Entity
{
    public Guid TripId { get; set; }
    public Guid SpaceId { get; set; }
    public Guid FarmerUserId { get; set; }
    public Guid HostUserId { get; set; }
    public DateOnly Date { get; set; }
    public TimeOnly From { get; set; }
    public TimeOnly To { get; set; }
    public decimal Fee { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Requested;
    /// <summary>The farmer's note to the host.</summary>
    public string? Message { get; set; }
    /// <summary>Why it was declined or cancelled, shown to the other side.</summary>
    public string? Reason { get; set; }
    /// <summary>Declined because the host confirmed another farmer for the same day (no reason typed).</summary>
    public bool SlotTaken { get; set; }
    /// <summary>"Farmer" or "Host" for a cancelled booking.</summary>
    public string? CancelledBy { get; set; }
    public DateTime? RespondedAt { get; set; }
    /// <summary>When the farmer checked in at the space (UTC), from within <see cref="ArrivalRules.MaxDistanceMeters"/>.</summary>
    public DateTime? ArrivedAt { get; set; }
    /// <summary>How far from the space the farmer's phone was at check-in, in metres.</summary>
    public int? ArrivalDistanceMeters { get; set; }
    /// <summary>When the host marked that the farmer did not come (only after the slot ended without a check-in).</summary>
    public DateTime? NoShowAt { get; set; }
    /// <summary>
    /// Random code in the public link the host shares with neighbours (/s/{code}); made the first time they share.
    /// Random rather than the booking id, so links cannot be guessed or listed.
    /// </summary>
    public string? ShareCode { get; set; }

    public bool IsActive => Status is BookingStatus.Requested or BookingStatus.Accepted;

    /// <summary>Waiting or confirmed for today or later: what deleting the space has to cancel.</summary>
    public bool IsUpcoming(DateOnly today) => IsActive && Date >= today;

    /// <param name="by">"Farmer" or "Host".</param>
    public void Cancel(string by, string? reason)
    {
        Status = BookingStatus.Cancelled;
        CancelledBy = by;
        Reason = reason;
        UpdatedAt = DateTime.UtcNow;
    }
}
