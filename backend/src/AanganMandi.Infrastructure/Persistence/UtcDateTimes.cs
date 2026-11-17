using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace AanganMandi.Infrastructure.Persistence;

/// <summary>
/// Every DateTime in the database is UTC. SQL Server's datetime2 has no time zone, so EF would read values back with
/// Kind = Unspecified and the JSON would lack the trailing "Z": the app would then read 06:47 UTC as 06:47 local time.
/// These converters mark values UTC on the way out of the database, and turn any local time into UTC on the way in.
/// Registered for all DateTime properties in <see cref="AppDbContext.ConfigureConventions"/>.
/// </summary>
public static class UtcDateTimes
{
    public static DateTime ToStore(DateTime v) => v.Kind == DateTimeKind.Local ? v.ToUniversalTime() : v;
    public static DateTime FromStore(DateTime v) => DateTime.SpecifyKind(v, DateTimeKind.Utc);

    public sealed class Converter() : ValueConverter<DateTime, DateTime>(v => ToStore(v), v => FromStore(v));

    public sealed class NullableConverter() : ValueConverter<DateTime?, DateTime?>(
        v => v.HasValue ? ToStore(v.Value) : v, v => v.HasValue ? FromStore(v.Value) : v);
}
