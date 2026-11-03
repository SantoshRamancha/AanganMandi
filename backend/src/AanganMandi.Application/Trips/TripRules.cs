using AanganMandi.Domain.Spaces;

namespace AanganMandi.Application.Trips;

/// <summary>Pure rules for trips and space bookings (no database), so they can be unit-tested.</summary>
public static class TripRules
{
    /// <summary>How far ahead a trip can be planned.</summary>
    public const int MaxDaysAhead = 60;

    /// <summary>Trips and slots are in Hyderabad: "today" is the India date, not the server's.</summary>
    public static DateOnly TodayInIndia(DateTime utcNow) => DateOnly.FromDateTime(utcNow.AddHours(5.5));

    /// <summary>Null when the date can be planned, else the reason it cannot.</summary>
    public static string? CheckDate(DateOnly date, DateOnly today) =>
        date < today ? "Choose today or a later date" :
        date > today.AddDays(MaxDaysAhead) ? $"Trips can be planned up to {MaxDaysAhead} days ahead" :
        null;

    /// <summary>The space's "largest vehicle that can enter" is at least the trip's vehicle (enum order is size order).</summary>
    public static bool VehicleFits(VehicleType spaceMax, VehicleType tripVehicle) => tripVehicle <= spaceMax;

    /// <summary>Whether a space with these weekly days ("Monday,Saturday") is open on <paramref name="date"/>.</summary>
    public static bool OpenOn(string availableDays, DateOnly date) =>
        availableDays.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Contains(date.DayOfWeek.ToString());
}
