using AanganMandi.Application.Identity;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Storage;
using AanganMandi.Infrastructure.Notifications;
using AanganMandi.Infrastructure.Persistence;
using Hangfire;
using Kinichit.Communication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using StorageProvider;

namespace AanganMandi.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config, string contentRoot)
    {
        // Factory for background work; scoped AppDbContext for API requests.
        services.AddDbContextFactory<AppDbContext>(o => o.UseSqlServer(
            config.GetConnectionString("Default"),
            sql => sql.UseNetTopologySuite()));
        services.AddScoped(sp => sp.GetRequiredService<IDbContextFactory<AppDbContext>>().CreateDbContext());
        services.AddSingleton<IOtpService, DevOtpService>();

        // Uploaded files: the object storage bucket (StorageProvider, keys in user-secrets) or local disk.
        if (UsesBucket(config))
        {
            services.AddStorageProvider(config.GetSection(StorageProviderOptions.Section));
            services.AddSingleton<IFileStorage>(sp =>
                new ObjectFileStorage(sp.GetRequiredService<IStorageProvider>(), config["Storage:KeyPrefix"]));
        }
        else
        {
            services.AddSingleton<IFileStorage>(new LocalFileStorage(LocalStorageRoot(config, contentRoot)));
        }

        // Email (Kinichit.Communication): provider from the "Email" section; mails are queued in this database
        // (EmailQueueItems) and sent by the Hangfire job set up in Program.cs.
        services.AddCommunication(config);
        services.AddEmailQueue(config);
        services.Configure<NotificationOptions>(config.GetSection("Notifications"));
        services.AddScoped<INotifier, EmailNotifier>();
        return services;
    }

    /// <summary>Storage:Provider = Object stores uploads in the bucket; anything else (default Local) on disk.</summary>
    public static bool UsesBucket(IConfiguration config) =>
        string.Equals(config["Storage:Provider"], "Object", StringComparison.OrdinalIgnoreCase);

    /// <summary>Storage:Root for local files, relative to the API project; defaults to backend/App_Data/uploads.</summary>
    public static string LocalStorageRoot(IConfiguration config, string contentRoot) =>
        Path.GetFullPath(Path.Combine(contentRoot, config["Storage:Root"] ?? "../../App_Data/uploads"));

    /// <summary>
    /// Copies every file under the local uploads folder into the bucket at the same relative path (under
    /// Storage:KeyPrefix), skipping files already there, so records saved before the switch keep working.
    /// </summary>
    public static async Task CopyLocalUploadsToBucketAsync(this IServiceProvider services, IConfiguration config,
        string contentRoot, TextWriter log, CancellationToken ct = default)
    {
        if (!UsesBucket(config))
        {
            await log.WriteLineAsync("Storage:Provider is not Object, so there is no bucket to copy to. Set it (and the StorageProvider keys) first.");
            return;
        }
        var root = LocalStorageRoot(config, contentRoot);
        var bucket = services.GetRequiredService<IStorageProvider>();
        var storage = (ObjectFileStorage)services.GetRequiredService<IFileStorage>();
        var files = Directory.Exists(root) ? Directory.GetFiles(root, "*", SearchOption.AllDirectories) : [];
        int copied = 0, skipped = 0;
        foreach (var file in files)
        {
            var key = storage.Key(Path.GetRelativePath(root, file).Replace('\\', '/'));
            if (await bucket.ExistsAsync(key, ct)) { skipped++; continue; }
            await using var content = File.OpenRead(file);
            await bucket.UploadAsync(key, content, ContentTypes.ForPath(file), ct);
            copied++;
        }
        await log.WriteLineAsync($"Copied {copied} file(s) from {root} to the bucket; {skipped} were already there.");
    }

    /// <summary>
    /// Recurring Hangfire jobs (times in UTC): send queued emails every 15 seconds, clear old ones daily at 03:00, and
    /// tell buyers about tomorrow's stalls near them at 12:30 UTC = 18:00 in India.
    /// </summary>
    public static void ScheduleBackgroundJobs(this IServiceProvider services)
    {
        var jobs = services.GetRequiredService<IRecurringJobManager>();
        jobs.AddOrUpdate<EmailQueueProcessor>("email-queue", p => p.ProcessAsync(CancellationToken.None), "*/15 * * * * *");
        jobs.AddOrUpdate<EmailQueueProcessor>("email-queue-cleanup", p => p.CleanUpAsync(CancellationToken.None), Cron.Daily(3));
        jobs.AddOrUpdate<INotifier>("nearby-day-before", n => n.NearbyTomorrowAsync(CancellationToken.None), "30 12 * * *");
    }
}
