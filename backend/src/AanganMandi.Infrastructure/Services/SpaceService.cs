using AanganMandi.Application.Files;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Storage;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Spaces;
using AanganMandi.Infrastructure.Accounts;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace AanganMandi.Infrastructure.Services;

public sealed record SpaceInput(string Title, SpaceType Type, string Address, string Locality,
    double Latitude, double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle,
    Amenities[] Amenities, bool IsFree, decimal Fee, string? Rules, DayOfWeek[] AvailableDays,
    TimeOnly OpenFrom, TimeOnly OpenTo);

/// <summary>
/// The host's spaces: create and edit (a change to a live or rejected space sends it back through review), photos
/// and the right-to-use proof, submit for review, delete. Admin decisions are in <see cref="ReviewService"/>.
/// </summary>
public class SpaceService(AppDbContext db, IFileStorage storage, INotifier notifier)
{
    public const long MaxUploadBytes = 8 * 1024 * 1024;
    public const int MinPhotos = 3, MaxPhotos = 8;

    /// <summary>The reason a farmer sees on a booking cancelled because the host deleted the space.</summary>
    public const string SpaceDeletedReason = "The host removed this space from Aangan Mandi";

    private static readonly GeometryFactory Geo = NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public Task<List<Space>> ListAsync(Guid hostId, CancellationToken ct) =>
        db.Spaces.Include(s => s.Photos).Where(s => s.HostUserId == hostId).OrderByDescending(s => s.CreatedAt).ToListAsync(ct);

    public async Task<Space> GetAsync(Guid hostId, Guid spaceId, CancellationToken ct) =>
        await db.Spaces.Include(s => s.Photos).SingleOrDefaultAsync(s => s.Id == spaceId && s.HostUserId == hostId, ct)
        ?? throw ApiException.NotFound();

    public async Task<Space> CreateAsync(Guid hostId, SpaceInput input, CancellationToken ct)
    {
        Validate(input);
        var space = new Space
        {
            HostUserId = hostId,
            Title = input.Title.Trim(),
            Address = input.Address.Trim(),
            Locality = input.Locality.Trim(),
            Location = Geo.CreatePoint(new Coordinate(input.Longitude, input.Latitude)),
            AvailableDays = "",
        };
        Apply(space, input);
        db.Spaces.Add(space);
        await db.SaveChangesAsync(ct);
        return space;
    }

    public async Task<Space> UpdateAsync(Guid hostId, Guid spaceId, SpaceInput input, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        if (space.Status is SpaceStatus.PendingReview) throw ApiException.Conflict("space_under_review");
        Validate(input);
        Apply(space, input);
        // Any change to a live or rejected space sends it back through review.
        if (space.Status is SpaceStatus.Live or SpaceStatus.Rejected) space.Status = SpaceStatus.Draft;
        await db.SaveChangesAsync(ct);
        return space;
    }

    /// <summary>
    /// Adds a photo, or sets the proof (replacing any earlier one). Allowed until the space is approved; while it waits
    /// for review it stays in the queue and the reviewer sees the new file.
    /// </summary>
    public async Task AddFileAsync(Guid hostId, Guid spaceId, Upload file, bool isProof, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        RequireFilesOpen(space);
        var kind = await CheckUploadAsync(file, ct);
        if (!isProof && space.Photos.Count(p => !p.IsRightToUseProof) >= MaxPhotos)
            throw ApiException.BadRequest("space_max_photos", ("max", MaxPhotos));

        var path = await SaveAsync(space, file, kind, isProof, ct);
        var oldProof = isProof ? space.Photos.Where(p => p.IsRightToUseProof).ToList() : [];
        db.SpacePhotos.RemoveRange(oldProof);
        db.SpacePhotos.Add(new SpacePhoto { SpaceId = space.Id, FilePath = path, IsRightToUseProof = isProof });
        Touch(space);
        await db.SaveChangesAsync(ct);
        foreach (var p in oldProof) await storage.DeleteAsync(p.FilePath, ct);
    }

    /// <summary>One photo or the proof, for the host to preview or download (the proof is private).</summary>
    public async Task<(Stream Content, string Path)> OpenFileAsync(Guid hostId, Guid spaceId, Guid photoId, CancellationToken ct)
    {
        var photo = (await GetAsync(hostId, spaceId, ct)).Photos.SingleOrDefault(p => p.Id == photoId)
            ?? throw ApiException.NotFound();
        var stream = await storage.OpenReadAsync(photo.FilePath, ct) ?? throw ApiException.NotFound();
        return (stream, photo.FilePath);
    }

    /// <summary>Replaces one photo or the proof with a new file, keeping its place in the list.</summary>
    public async Task ReplaceFileAsync(Guid hostId, Guid spaceId, Guid photoId, Upload file, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        var photo = space.Photos.SingleOrDefault(p => p.Id == photoId) ?? throw ApiException.NotFound();
        RequireFilesOpen(space);
        var kind = await CheckUploadAsync(file, ct);

        var old = photo.FilePath;
        photo.FilePath = await SaveAsync(space, file, kind, photo.IsRightToUseProof, ct);
        photo.UpdatedAt = DateTime.UtcNow;
        Touch(space);
        await db.SaveChangesAsync(ct);
        await storage.DeleteAsync(old, ct);
    }

    /// <summary>
    /// Deletes one photo or the proof. If a waiting space drops below the minimum photos or loses its proof it cannot
    /// be reviewed, so it goes back to Draft (returns true) and the host submits again.
    /// </summary>
    public async Task<bool> DeleteFileAsync(Guid hostId, Guid spaceId, Guid photoId, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        var photo = space.Photos.SingleOrDefault(p => p.Id == photoId) ?? throw ApiException.NotFound();
        RequireFilesOpen(space);

        db.SpacePhotos.Remove(photo);
        space.Photos.Remove(photo);
        var complete = space.Photos.Count(p => !p.IsRightToUseProof) >= MinPhotos && space.Photos.Any(p => p.IsRightToUseProof);
        var withdrawn = space.Status is SpaceStatus.PendingReview && !complete;
        if (withdrawn) space.Status = SpaceStatus.Draft;
        Touch(space);
        await db.SaveChangesAsync(ct);
        await storage.DeleteAsync(photo.FilePath, ct);
        return withdrawn;
    }

    /// <summary>
    /// Deletes the space, whatever its status: it leaves search and the review queue, its files are removed, and every
    /// waiting or confirmed booking for today or later is cancelled with the farmer told why. Returns how many.
    /// </summary>
    public async Task<int> DeleteAsync(Guid hostId, Guid spaceId, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        var (files, cancelled) = await SpaceRemoval.PrepareAsync(db, space, SpaceDeletedReason, ct);
        await db.SaveChangesAsync(ct);
        foreach (var f in files) await storage.DeleteAsync(f, ct);
        foreach (var b in cancelled) await notifier.BookingChangedAsync(b.Id, ct);
        return cancelled.Count;
    }

    public async Task SubmitAsync(Guid hostId, Guid spaceId, CancellationToken ct)
    {
        var space = await GetAsync(hostId, spaceId, ct);
        if (space.Status is not (SpaceStatus.Draft or SpaceStatus.Rejected)) throw ApiException.Conflict("space_already_submitted");
        if (space.Photos.Count(p => !p.IsRightToUseProof) < MinPhotos)
            throw ApiException.Unprocessable("space_min_photos", ("min", MinPhotos));
        if (!space.Photos.Any(p => p.IsRightToUseProof)) throw ApiException.Unprocessable("space_proof_required");
        space.Status = SpaceStatus.PendingReview;
        space.RejectionReason = null;
        space.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.SpaceSubmittedAsync(space.Id, ct);
    }

    // ---------------------------------------------------------------------------------------------

    /// <summary>An approved (live) space's photos and proof are final: preview and download only.</summary>
    private static void RequireFilesOpen(Space s)
    {
        if (s.Status is SpaceStatus.Live) throw ApiException.Conflict("space_files_locked");
    }

    /// <summary>The photo's real format, read from its bytes (the label the browser sends can be wrong).</summary>
    internal static async Task<ImageFormat.Kind> CheckUploadAsync(Upload file, CancellationToken ct)
    {
        if (file.Length is 0 or > MaxUploadBytes) throw ApiException.BadRequest("photo_too_big", ("mb", 8));
        await using var head = file.Open();
        return await ImageFormat.DetectAsync(head, ct) ?? throw ApiException.BadRequest("photo_format");
    }

    /// <summary>Proof documents are private (kyc/); space photos are public (spaces/).</summary>
    private async Task<string> SaveAsync(Space space, Upload file, ImageFormat.Kind kind, bool isProof, CancellationToken ct)
    {
        var folder = isProof ? $"kyc/spaces/{space.Id:N}" : $"spaces/{space.Id:N}";
        await using var stream = file.Open();
        return await storage.SaveAsync(stream, folder, kind.Extension, ct);
    }

    /// <summary>A change to a rejected space starts a new draft; a waiting one stays in the queue.</summary>
    private static void Touch(Space s)
    {
        if (s.Status is SpaceStatus.Rejected) s.Status = SpaceStatus.Draft;
        s.UpdatedAt = DateTime.UtcNow;
    }

    private static void Validate(SpaceInput r)
    {
        string? error =
            string.IsNullOrWhiteSpace(r.Title) ? "space_name_required" :
            string.IsNullOrWhiteSpace(r.Address) || string.IsNullOrWhiteSpace(r.Locality) ? "space_address_required" :
            r.Latitude is < -90 or > 90 || r.Longitude is < -180 or > 180 || (r.Latitude == 0 && r.Longitude == 0) ? "space_location_required" :
            r.AreaSqFt is < 50 or > 100_000 ? "space_area_range" :
            !r.IsFree && r.Fee is <= 0 or > 100_000 ? "space_fee_required" :
            r.AvailableDays is not { Length: > 0 } ? "space_days_required" :
            (r.OpenTo - r.OpenFrom).TotalHours is < 2 or > 6 ? "space_slot_length" :
            null;
        if (error is not null) throw ApiException.BadRequest(error);
    }

    private static void Apply(Space s, SpaceInput r)
    {
        s.Title = r.Title.Trim();
        s.Type = r.Type;
        s.Address = r.Address.Trim();
        s.Locality = r.Locality.Trim();
        s.Location = Geo.CreatePoint(new Coordinate(r.Longitude, r.Latitude));
        s.AreaSqFt = r.AreaSqFt;
        s.MaxStallSize = string.IsNullOrWhiteSpace(r.MaxStallSize) ? "10x10 ft" : r.MaxStallSize.Trim();
        s.MaxVehicle = r.MaxVehicle;
        s.Amenities = (r.Amenities ?? []).Aggregate(Amenities.None, (all, a) => all | a);
        s.IsFree = r.IsFree;
        s.Fee = r.IsFree ? 0 : r.Fee;
        s.Rules = r.Rules?.Trim();
        s.AvailableDays = string.Join(',', r.AvailableDays.Distinct().Order());
        s.OpenFrom = r.OpenFrom;
        s.OpenTo = r.OpenTo;
        s.UpdatedAt = DateTime.UtcNow;
    }
}
