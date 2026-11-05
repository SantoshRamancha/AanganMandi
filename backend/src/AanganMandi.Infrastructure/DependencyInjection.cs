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
        // Defaults to backend/App_Data/uploads.
        var storageRoot = Path.GetFullPath(Path.Combine(contentRoot, config["Storage:Root"] ?? "../../App_Data/uploads"));
        services.AddSingleton<IFileStorage>(new LocalFileStorage(storageRoot));

        // Email (Kinichit.Communication): provider from the "Email" section; mails are queued in this database
        // (EmailQueueItems) and sent by the Hangfire job set up in Program.cs.
        services.AddCommunication(config);
        services.AddEmailQueue(config);
        services.Configure<NotificationOptions>(config.GetSection("Notifications"));
        services.AddScoped<INotifier, EmailNotifier>();
        return services;
    }

    /// <summary>Recurring Hangfire jobs: send queued emails every 15 seconds, and clear old ones daily at 03:00.</summary>
    public static void ScheduleBackgroundJobs(this IServiceProvider services)
    {
        var jobs = services.GetRequiredService<IRecurringJobManager>();
        jobs.AddOrUpdate<EmailQueueProcessor>("email-queue", p => p.ProcessAsync(CancellationToken.None), "*/15 * * * * *");
        jobs.AddOrUpdate<EmailQueueProcessor>("email-queue-cleanup", p => p.CleanUpAsync(CancellationToken.None), Cron.Daily(3));
    }
}
