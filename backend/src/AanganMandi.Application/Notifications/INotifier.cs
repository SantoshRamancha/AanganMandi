namespace AanganMandi.Application.Notifications;

/// <summary>
/// Tells people by email when something happens to them. Each method reads the current state from the database and
/// emails only users who saved an email address, in their app language. Never throws: a failed notification must not
/// undo or fail the action that triggered it (the failure is logged).
/// </summary>
public interface INotifier
{
    /// <summary>To the farmer ("we received it") and to the verifier it was assigned to.</summary>
    Task FarmerSubmittedAsync(Guid farmerUserId, CancellationToken ct = default);

    /// <summary>To the farmer: approved, or rejected with the reason.</summary>
    Task FarmerDecidedAsync(Guid farmerUserId, CancellationToken ct = default);

    /// <summary>To the verifier an admin (re)assigned the farmer to.</summary>
    Task FarmerAssignedAsync(Guid farmerUserId, CancellationToken ct = default);

    /// <summary>Welcome to a newly added verifier.</summary>
    Task VerifierAddedAsync(Guid verifierUserId, Guid addedByUserId, CancellationToken ct = default);

    /// <summary>To the host ("we received it") and to the admins who approve spaces.</summary>
    Task SpaceSubmittedAsync(Guid spaceId, CancellationToken ct = default);

    /// <summary>To the host: live, or rejected with the reason.</summary>
    Task SpaceDecidedAsync(Guid spaceId, CancellationToken ct = default);

    /// <summary>
    /// After any booking change, to the side that needs to know: a new request → host; accepted or declined → farmer;
    /// cancelled → the other side.
    /// </summary>
    Task BookingChangedAsync(Guid bookingId, CancellationToken ct = default);

    /// <summary>
    /// The farmer checked in at the space: to the host ("your farmer is here"), and to every buyer whose saved area
    /// covers the space and who has alerts on ("selling now"). Each buyer gets it once per booking.
    /// </summary>
    Task FarmerArrivedAsync(Guid bookingId, CancellationToken ct = default);

    /// <summary>
    /// Daily job, the evening before: one email per buyer listing tomorrow's confirmed stalls inside their area.
    /// A booking already announced to a buyer is skipped, so running it twice sends nothing new.
    /// </summary>
    Task NearbyTomorrowAsync(CancellationToken ct = default);
}
