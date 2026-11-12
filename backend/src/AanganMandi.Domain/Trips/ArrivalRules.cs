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

    /// <summary>
    /// Marks a stored UTC time as UTC. SQL Server hands datetime2 back without a kind, so the JSON would lack the
    /// trailing "Z" and the app would read 06:47 UTC as 06:47 local time.
    /// </summary>
    public static DateTime? AsUtc(DateTime? t) => t is { } v ? DateTime.SpecifyKind(v, DateTimeKind.Utc) : null;

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
    public static string? CheckArrival(Booking b, DateTime indiaNow, double distanceMeters)
    {
        if (b.Status != BookingStatus.Accepted) return "Only a confirmed booking can be checked in";
        if (b.ArrivedAt is not null) return "You already checked in";
        var today = DateOnly.FromDateTime(indiaNow);
        if (b.Date != today) return b.Date > today ? "Check in on the day of your booking" : "This booking's day has passed";
        var now = TimeOnly.FromDateTime(indiaNow);
        if (now < b.From.Add(-EarlyWindow)) return $"Check-in opens at {b.From.Add(-EarlyWindow):HH\\:mm}";
        if (now >= b.To) return "Your slot has ended";
        if (distanceMeters > MaxDistanceMeters)
            return $"You are about {RoundedMeters(distanceMeters)} m from the space. Check in when you reach it";
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
