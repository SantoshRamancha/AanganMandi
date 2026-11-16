using System.Globalization;
using System.Net;
using System.Text;
using System.Threading.Channels;
using Kinichit.Communication;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Serilog.Core;
using Serilog.Events;

namespace AanganMandi.Infrastructure.Logging;

/// <summary>Configuration section <c>Alerts</c>: who gets an email when the API logs errors.</summary>
public sealed class ErrorAlertOptions
{
    /// <summary>Addresses to email. Empty = no alerts (errors are still in the log files).</summary>
    public string[] Emails { get; set; } = [];
    /// <summary>At most one alert email per this many minutes; errors in between go into the next one.</summary>
    public int MinMinutesBetween { get; set; } = 15;
    /// <summary>After the first error, wait this long for related ones so they arrive as one email.</summary>
    public int CollectSeconds { get; set; } = 60;
}

/// <summary>
/// Serilog sink for Error and Fatal events: hands them to <see cref="ErrorAlertService"/> without blocking the
/// request that logged them. One instance, created before the host so the logger can use it.
/// </summary>
public sealed class ErrorAlertSink : ILogEventSink
{
    public static readonly ErrorAlertSink Instance = new();
    public const int MaxBuffered = 500;

    private readonly Channel<LogEvent> _events = Channel.CreateBounded<LogEvent>(
        new BoundedChannelOptions(MaxBuffered) { FullMode = BoundedChannelFullMode.DropWrite });

    public ChannelReader<LogEvent> Reader => _events.Reader;

    public void Emit(LogEvent e)
    {
        if (e.Level < LogEventLevel.Error) return;
        // A failure to send an alert must not trigger another alert.
        if (e.Properties.TryGetValue("SourceContext", out var src) && src.ToString().Contains(nameof(ErrorAlertService))) return;
        _events.Writer.TryWrite(e);
    }
}

/// <summary>
/// Collects logged errors and emails them to <see cref="ErrorAlertOptions.Emails"/>: the first error waits
/// <see cref="ErrorAlertOptions.CollectSeconds"/> for others, then one email lists them; no more than one email per
/// <see cref="ErrorAlertOptions.MinMinutesBetween"/>. Sends directly through the email provider (not the database
/// queue), so an alert still goes out when the database is the problem.
/// </summary>
public sealed class ErrorAlertService(ErrorAlertSink sink, IServiceScopeFactory scopes, IOptions<ErrorAlertOptions> options,
    IHostEnvironment env, Microsoft.Extensions.Logging.ILogger<ErrorAlertService> log) : BackgroundService
{
    public const int MaxListed = 25;

    protected override async Task ExecuteAsync(CancellationToken stop)
    {
        var o = options.Value;
        var lastSent = DateTime.MinValue;
        var batch = new List<LogEvent>();
        var dropped = 0;

        while (await sink.Reader.WaitToReadAsync(stop))
        {
            // Collect for a while, and keep collecting until the minimum gap since the last email has passed.
            var sendAt = new[] { DateTime.UtcNow.AddSeconds(o.CollectSeconds), lastSent.AddMinutes(o.MinMinutesBetween) }.Max();
            do
            {
                while (sink.Reader.TryRead(out var e))
                {
                    if (batch.Count < MaxListed) batch.Add(e); else dropped++;
                }
                var wait = sendAt - DateTime.UtcNow;
                if (wait <= TimeSpan.Zero) break;
                await Task.Delay(wait < TimeSpan.FromSeconds(5) ? wait : TimeSpan.FromSeconds(5), stop);
            } while (true);

            if (o.Emails.Length > 0 && batch.Count > 0)
            {
                try
                {
                    var (subject, html) = Compose(batch, dropped, env.EnvironmentName);
                    using var scope = scopes.CreateScope();
                    var sender = scope.ServiceProvider.GetRequiredService<IEmailSender>();
                    await sender.SendAsync(new EmailMessage(o.Emails.Select(a => new EmailAddress(a, null)).ToList(), subject)
                        { HtmlBody = html }, stop);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    // Logged as a warning: a failed alert must not create another alert.
                    log.LogWarning(ex, "Could not send the error alert email");
                }
            }
            lastSent = DateTime.UtcNow;
            batch.Clear();
            dropped = 0;
        }
    }

    /// <summary>The alert email: one row per error (India time, level, where, message, exception), oldest first.</summary>
    public static (string Subject, string Html) Compose(IReadOnlyList<LogEvent> events, int moreNotListed, string environment)
    {
        var total = events.Count + moreNotListed;
        var subject = $"[Aangan Mandi {environment}] {total} error{(total == 1 ? "" : "s")} in the API";
        var h = new StringBuilder();
        h.Append("<div style=\"font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1d2a1f\">");
        h.Append($"<p><b>{total}</b> error{(total == 1 ? " was" : "s were")} logged by the Aangan Mandi API ({E(environment)}). ");
        h.Append("Full details are in the API log files.</p>");
        h.Append("<table cellpadding=\"6\" style=\"border-collapse:collapse;border:1px solid #ccc\">");
        h.Append("<tr style=\"background:#eef3ea\"><th align=left>Time (India)</th><th align=left>Level</th><th align=left>Where</th><th align=left>Message</th></tr>");
        foreach (var e in events.OrderBy(e => e.Timestamp))
        {
            var when = e.Timestamp.ToUniversalTime().AddHours(5.5).ToString("dd MMM HH:mm:ss", CultureInfo.InvariantCulture);
            var where = e.Properties.TryGetValue("RequestPath", out var path) ? path.ToString().Trim('"')
                : e.Properties.TryGetValue("SourceContext", out var src) ? src.ToString().Trim('"') : "";
            var message = e.RenderMessage(CultureInfo.InvariantCulture);
            if (e.Exception is { } ex) message += $" — {ex.GetType().Name}: {ex.Message}";
            h.Append($"<tr style=\"border-top:1px solid #ddd\"><td>{when}</td><td>{e.Level}</td><td>{E(where)}</td><td>{E(Shorten(message, 600))}</td></tr>");
        }
        h.Append("</table>");
        if (moreNotListed > 0) h.Append($"<p>…and {moreNotListed} more not listed here.</p>");
        h.Append("</div>");
        return (subject, h.ToString());
    }

    private static string Shorten(string s, int max) => s.Length <= max ? s : s[..max] + "…";
    private static string E(string s) => WebUtility.HtmlEncode(s);
}
