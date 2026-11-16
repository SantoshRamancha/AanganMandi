using System.Collections.Concurrent;

namespace AanganMandi.Infrastructure;

/// <summary>
/// Limits OTP requests per phone, so nobody can run up SMS costs or flood someone's phone: a short wait between two
/// requests, and a cap per rolling hour. In memory, so the limits are per API instance and reset on restart; the
/// per-IP limit in the API (rate limiter "otp") covers someone trying many numbers.
/// </summary>
public class OtpThrottle(Func<DateTime>? clock = null)
{
    public static readonly TimeSpan Cooldown = TimeSpan.FromSeconds(30);
    public const int MaxPerHour = 5;

    private readonly Func<DateTime> _now = clock ?? (() => DateTime.UtcNow);
    private readonly ConcurrentDictionary<string, List<DateTime>> _sends = new();

    /// <summary>
    /// Records a send for <paramref name="phone"/> and returns null, or returns how long to wait (nothing is recorded).
    /// </summary>
    public TimeSpan? TrySend(string phone)
    {
        var now = _now();
        var list = _sends.GetOrAdd(phone, _ => []);
        lock (list)
        {
            list.RemoveAll(t => now - t >= TimeSpan.FromHours(1));
            if (list.Count > 0 && now - list[^1] < Cooldown) return Cooldown - (now - list[^1]);
            if (list.Count >= MaxPerHour) return list[0].AddHours(1) - now;
            list.Add(now);
            return null;
        }
    }
}
