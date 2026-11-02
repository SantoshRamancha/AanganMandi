namespace AanganMandi.Application.Identity;

/// <summary>Sends and checks login OTPs. The dev implementation logs codes; production uses a DLT-registered SMS gateway.</summary>
public interface IOtpService
{
    /// <summary>
    /// Sends a new OTP. Returns the code itself only for testing, when no SMS is sent and Otp:ShowDevCode is on,
    /// so the app can display it. A real SMS sender always returns null.
    /// </summary>
    Task<string?> SendAsync(string phone, CancellationToken ct = default);
    Task<bool> VerifyAsync(string phone, string code, CancellationToken ct = default);
}
