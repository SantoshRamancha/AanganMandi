using System.Security.Cryptography;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace AanganMandi.IntegrationTests;

/// <summary>
/// The whole API in memory (real controllers, services, auth, EF Core) against a throw-away SQL Server database,
/// made fresh for each test run from the migrations and dropped at the end.
///
/// SQL Server comes from the environment variable <c>AANGAN_TEST_SQL</c> (a connection string without a database),
/// e.g. the GitHub Actions service container; locally the default instance with Windows sign-in is used. Nothing
/// touches the dev database, the bucket or real email: files go to a temp folder, emails to the log, background jobs
/// are off.
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly string _database = $"AanganMandi_IT_{Guid.NewGuid():N}"[..32];
    private readonly string _files = Path.Combine(Path.GetTempPath(), "aangan-it", Guid.NewGuid().ToString("N"));

    public string ConnectionString { get; }

    public ApiFactory()
    {
        var server = Environment.GetEnvironmentVariable("AANGAN_TEST_SQL") is { Length: > 0 } fromEnv
            ? fromEnv
            : "Server=localhost;Trusted_Connection=True;TrustServerCertificate=True";
        ConnectionString = new SqlConnectionStringBuilder(server) { InitialCatalog = _database }.ConnectionString;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        // UseSetting values are seen by Program.cs while it builds (Jwt:Key, the connection string, ...).
        builder.UseSetting("ConnectionStrings:Default", ConnectionString);
        builder.UseSetting("Jwt:Key", Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)));
        builder.UseSetting("Jwt:Issuer", "aangan-integration-tests");
        builder.UseSetting("Otp:ShowDevCode", "true");
        builder.UseSetting("Storage:Provider", "Local");
        builder.UseSetting("Storage:Root", Path.Combine(_files, "uploads"));
        builder.UseSetting("Logs:Directory", Path.Combine(_files, "logs"));
        builder.UseSetting("Email:Provider", "Log");
        builder.UseSetting("Sms:Provider", "Log");
        builder.UseSetting("BackgroundJobs:Enabled", "false");
        builder.UseSetting("RateLimits:OtpPerIp", "10000");
    }

    public async Task InitializeAsync()
    {
        using var scope = Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        using (var scope = Services.CreateScope())
            await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.EnsureDeletedAsync();
        await DisposeAsync();
        SqlConnection.ClearAllPools();
        try { Directory.Delete(_files, recursive: true); } catch (IOException) { } catch (UnauthorizedAccessException) { }
    }

    /// <summary>Runs <paramref name="work"/> against the test database (to arrange what the API can't, like a past date).</summary>
    public async Task DbAsync(Func<AppDbContext, Task> work)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await work(db);
        await db.SaveChangesAsync();
    }

    public async Task<T> QueryAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        using var scope = Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}

/// <summary>One API and database for all the test classes (they use different users, so they don't collide).</summary>
[CollectionDefinition(Name)]
public class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}
