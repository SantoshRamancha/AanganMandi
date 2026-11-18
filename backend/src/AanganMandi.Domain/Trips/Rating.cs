using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Trips;

/// <summary>Who gave a rating: the farmer (about the space and its host) or the host (about the farmer).</summary>
public enum RatingSide { Farmer, Host }

/// <summary>
/// After a confirmed stall, the farmer rates the space and the host rates the farmer: 1–5 stars and an optional
/// comment, once each, within <see cref="RatingRules.WindowDays"/> days. Averages show on space cards (to farmers)
/// and farmer cards (to hosts), so both sides can choose who to deal with.
/// </summary>
public class Rating : Entity
{
    public Guid BookingId { get; set; }
    /// <summary>The booking's space, copied so a space's average needs no join.</summary>
    public Guid SpaceId { get; set; }
    public Guid RaterUserId { get; set; }
    public Guid RatedUserId { get; set; }
    public RatingSide By { get; set; }
    public int Stars { get; set; }
    public string? Comment { get; set; }
}

/// <summary>An average of 1–5 stars from <see cref="Count"/> ratings; Average is null with none.</summary>
public sealed record StarSummary(double? Average, int Count)
{
    public static readonly StarSummary None = new(null, 0);

    public static StarSummary Of(IEnumerable<int> stars)
    {
        var list = stars.ToList();
        return list.Count == 0 ? None : new StarSummary(Math.Round(list.Average(), 1), list.Count);
    }
}

public static class RatingRules
{
    public const int MaxComment = 300;
    /// <summary>Days after the booking date during which it can be rated.</summary>
    public const int WindowDays = 14;

    /// <summary>The slot has ended (India time): a stall can be rated only once it happened.</summary>
    public static bool SlotOver(Booking b, DateTime indiaNow)
    {
        var today = DateOnly.FromDateTime(indiaNow);
        return b.Date < today || (b.Date == today && TimeOnly.FromDateTime(indiaNow) >= b.To);
    }

    /// <summary>
    /// Whether <paramref name="side"/> may rate this booking now: confirmed, slot over, still inside the window. A farmer
    /// marked as not coming has nothing to rate; the host can still rate them.
    /// </summary>
    public static bool CanRate(Booking b, RatingSide side, DateTime indiaNow) => WhyNot(b, side, indiaNow) is null;

    public static ApiError? WhyNot(Booking b, RatingSide side, DateTime indiaNow)
    {
        if (b.Status != BookingStatus.Accepted) return new ApiError("rating_not_confirmed");
        if (!SlotOver(b, indiaNow)) return new ApiError("rating_too_early");
        if (DateOnly.FromDateTime(indiaNow) > b.Date.AddDays(WindowDays)) return ApiError.Of("rating_too_late", ("days", WindowDays));
        if (side == RatingSide.Farmer && b.NoShowAt is not null) return new ApiError("rating_no_show");
        return null;
    }

    /// <summary>Null when the stars and comment are fine.</summary>
    public static ApiError? CheckInput(int stars, string? comment) =>
        stars is < 1 or > 5 ? new ApiError("rating_stars") :
        comment?.Trim().Length > MaxComment ? ApiError.Of("rating_comment_long", ("max", MaxComment)) :
        null;
}

/// <summary>
/// Farmers who book and do not come cost hosts a day. A host marks a no-show after the slot (see
/// <see cref="ArrivalRules.CanMarkNoShow"/>); hosts see the count on requests, and a farmer with
/// <see cref="Limit"/> or more in the last <see cref="WindowDays"/> days cannot request new slots until older ones
/// drop out of the window or an admin clears a wrong one.
/// </summary>
public static class NoShowPolicy
{
    public const int Limit = 3;
    public const int WindowDays = 90;

    public static DateTime WindowStart(DateTime utcNow) => utcNow.AddDays(-WindowDays);

    public static ApiError? CheckCanBook(int recentNoShows) => recentNoShows >= Limit
        ? ApiError.Of("too_many_no_shows", ("count", recentNoShows), ("days", WindowDays))
        : null;
}

/// <summary>A farmer's record as hosts see it: stars from hosts, no-shows in the window, stalls they came to.</summary>
public sealed record FarmerRecord(double? Average, int Ratings, int RecentNoShows, int Completed)
{
    public static readonly FarmerRecord Empty = new(null, 0, 0, 0);
}
