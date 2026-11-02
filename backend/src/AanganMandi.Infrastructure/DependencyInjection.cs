using AanganMandi.Application.Identity;
using AanganMandi.Application.Storage;
using AanganMandi.Infrastructure.Persistence;
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
        return services;
    }
}
