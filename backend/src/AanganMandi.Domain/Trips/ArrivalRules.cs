namespace AanganMandi.Domain.Trips;

/// <summary>
/// The booking day: a farmer checks in at the space from their phone's GPS, and a host can mark a no-show once the
/// slot is over. Times are India times (slots are in Hyderabad).
/// </summary>
public static class ArrivalRules
{
    /// <summary>How close to the space the phone must be. Covers typical phone GPS error in a city.</summary>
    public const int MaxDistanceMeters = 200;

    /// <summary>Check-in opens this long before the slot starts (to set up the stall).</summary>
    public static readonly TimeSpan EarlyWindow = TimeSpan.FromMinutes(60);

    /// <summary>The India date and time for a UTC moment.</summary>
    public static DateTime IndiaTime(DateTime utc) => utc.AddHours(5.5);

    /// <summary>Great-circle distance in metres between two latitude/longitude points.</summary>
    public static double DistanceMeters(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadius = 6_371_000;
        static double Rad(double deg) => deg * Math.PI / 180;
        var dLat = Rad(lat2 - lat1);
        var dLon = Rad(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(Rad(lat1)) * Math.Cos(Rad(lat2)) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return 2 * earthRadius * Math.Asin(Math.Min(1, Math.Sqrt(a)));
    }

    /// <summary>Null when the farmer can check in now, else why not. <paramref name="indiaNow"/> = <see cref="IndiaTime"/>.</summary>
    public static Common.ApiError? CheckArrival(Booking b, DateTime indiaNow, double distanceMeters)
    {
        if (b.Status != BookingStatus.Accepted) return new("checkin_not_confirmed");
        if (b.ArrivedAt is not null) return new("already_checked_in");
        var today = DateOnly.FromDateTime(indiaNow);
        if (b.Date != today) return new(b.Date > today ? "checkin_future_day" : "checkin_day_passed");
        var now = TimeOnly.FromDateTime(indiaNow);
        if (now < b.From.Add(-EarlyWindow))
            return Common.ApiError.Of("checkin_not_open", ("time", b.From.Add(-EarlyWindow).ToString("HH:mm")));
        if (now >= b.To) return new("slot_ended");
        if (distanceMeters > MaxDistanceMeters) return Common.ApiError.Of("too_far", ("meters", RoundedMeters(distanceMeters)));
        return null;
    }

    /// <summary>The host may mark a no-show once the slot is over and the farmer never checked in.</summary>
    public static bool CanMarkNoShow(Booking b, DateTime indiaNow) =>
        b.Status == BookingStatus.Accepted && b.ArrivedAt is null && b.NoShowAt is null
        && (b.Date < DateOnly.FromDateTime(indiaNow)
            || (b.Date == DateOnly.FromDateTime(indiaNow) && TimeOnly.FromDateTime(indiaNow) >= b.To));

    /// <summary>A distance people can read: to the nearest 10 m under 1 km, else the nearest 100 m.</summary>
    public static int RoundedMeters(double m) => m < 1000 ? (int)Math.Round(m / 10) * 10 : (int)Math.Round(m / 100) * 100;
}
