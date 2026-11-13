using System.Security.Cryptography;

namespace AanganMandi.Domain.Trips;

/// <summary>What a shared stall link shows: coming (date and area), selling now (with the address), or over.</summary>
public enum StallState { Upcoming, SellingNow, Over }

/// <summary>Rules for the public stall page a host shares with neighbours.</summary>
public static class StallStatus
{
    /// <summary>No 0/O, 1/l/I, so a code read aloud or retyped from a poster still works.</summary>
    private const string Alphabet = "23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
    public const int CodeLength = 10;

    /// <summary>A new random share code (about 58 bits).</summary>
    public static string NewCode() => RandomNumberGenerator.GetString(Alphabet, CodeLength);

    /// <summary>Whether a code from a URL has the right shape (checked before any database lookup).</summary>
    public static bool LooksLikeCode(string? code) =>
        code is { Length: CodeLength } && code.All(c => Alphabet.Contains(c));

    /// <summary>
    /// Selling now: checked in and the slot is running. Upcoming: confirmed, slot not over. Over: anything else
    /// (cancelled, declined, a no-show, or the slot has ended).
    /// </summary>
    public static StallState StateOf(Booking b, DateTime indiaNow)
    {
        var today = DateOnly.FromDateTime(indiaNow);
        var now = TimeOnly.FromDateTime(indiaNow);
        if (b.Status != BookingStatus.Accepted || b.NoShowAt is not null) return StallState.Over;
        if (b.Date < today || (b.Date == today && now >= b.To)) return StallState.Over;
        return b.Date == today && b.ArrivedAt is not null ? StallState.SellingNow : StallState.Upcoming;
    }
}
