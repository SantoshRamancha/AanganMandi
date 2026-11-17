using System.Text;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using AanganMandi.Api.Auth;
using AanganMandi.Infrastructure;
using AanganMandi.Infrastructure.Accounts;
using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Errors;
using AanganMandi.Infrastructure.Logging;
using AanganMandi.Infrastructure.Persistence;
using Hangfire;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);
// Logs: the console, plus one file per day in Logs:Directory (kept 30 days, 20 MB a file). Errors also go to the
// alert sink, which emails them to Alerts:Emails (see ErrorAlertService).
var logDirectory = DependencyInjection.LogDirectory(builder.Configuration, builder.Environment.ContentRootPath);
builder.Host.UseSerilog((ctx, cfg) => cfg
    .ReadFrom.Configuration(ctx.Configuration)
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Hangfire", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(Path.Combine(logDirectory, "api-.log"),
        rollingInterval: RollingInterval.Day, retainedFileCountLimit: 30,
        fileSizeLimitBytes: 20 * 1024 * 1024, rollOnFileSizeLimit: true, shared: true,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {SourceContext} {RequestPath}{NewLine}  {Message:lj}{NewLine}{Exception}")
    .WriteTo.Sink(ErrorAlertSink.Instance, LogEventLevel.Error));

builder.Services.AddInfrastructure(builder.Configuration, builder.Environment.ContentRootPath);
builder.Services.AddScoped<TokenService>();
builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o =>
{
    // Request/response records are nested in their controllers and may share a name (DecisionRequest),
    // so nested types are named after their controller: "OpsSpaces.DecisionRequest".
    o.CustomSchemaIds(t => t.IsNested ? $"{t.DeclaringType!.Name.Replace("Controller", "")}.{t.Name}" : t.Name);
    // "Authorize" button in Swagger: paste the accessToken from /auth/otp/verify.
    o.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT",
    });
    o.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        [new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = [],
    });
});
// The signing key is a secret: user secrets in Development, environment/vault elsewhere. Never in appsettings.
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException(
    "Jwt:Key is not set. Run: dotnet user-secrets set Jwt:Key <random 64+ character string> --project backend/src/AanganMandi.Api");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Issuer"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
    };
    // A token outlives a deleted account (another phone may still be signed in): refuse it with 401 instead of
    // letting the request fail on the missing user. One primary-key lookup per call; deleted users are filtered.
    o.Events = new JwtBearerEvents
    {
        OnTokenValidated = async ctx =>
        {
            var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
            if (ctx.Principal is not { } principal || !await db.Users.AnyAsync(u => u.Id == principal.UserId()))
                ctx.Fail("This account no longer exists");
        },
    };
});
builder.Services.AddAuthorization();
// Browsers may call the API from the web app's address(es) in Cors:AllowedOrigins (e.g. "https://app.aanganmandi.in");
// in Development also from any localhost port, where the Flutter web build runs. The Android app is not a browser
// and needs no CORS.
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
var isDevelopment = builder.Environment.IsDevelopment();
builder.Services.AddCors(o => o.AddPolicy("App", p => p
    .SetIsOriginAllowed(origin => CorsOrigins.IsAllowed(origin, allowedOrigins, allowLoopback: isDevelopment))
    .AllowAnyHeader()
    .AllowAnyMethod()));
// OTP endpoints per IP address: 20 calls per 10 minutes (per phone limits are in AuthController). Behind a proxy,
// set up forwarded headers when deploying so this sees the client's address, not the proxy's.
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddPolicy("otp", http => RateLimitPartition.GetFixedWindowLimiter(
        http.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(10), QueueLimit = 0 }));
    o.OnRejected = async (ctx, ct) =>
    {
        ctx.HttpContext.Response.Headers.RetryAfter = "600";
        var lang = ErrorText.LanguageOf(ctx.HttpContext.Request.Headers.AcceptLanguage.ToString());
        await ctx.HttpContext.Response.WriteAsJsonAsync(new
        {
            status = 429, code = "too_many_attempts",
            title = ErrorText.Render(new ApiError("too_many_attempts"), lang),
        }, ct);
    };
});
// Background jobs (Hangfire tables in this database): sends the queued emails.
builder.Services.AddHangfire(c => c.UseSqlServerStorage(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddHangfireServer();

var app = builder.Build();

// One-time move to the bucket: dotnet run --project backend/src/AanganMandi.Api -- copy-uploads-to-bucket
// copies backend/App_Data/uploads into the bucket (skipping files already there), then exits without serving.
if (args.Contains("copy-uploads-to-bucket"))
{
    await app.Services.CopyLocalUploadsToBucketAsync(builder.Configuration, builder.Environment.ContentRootPath, Console.Out);
    return;
}

// Database setup on a server (Development migrates on start): dotnet AanganMandi.Api.dll migrate
// applies pending migrations and exits without serving. Run it on every deploy, before starting the new version.
if (args.Contains("migrate"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var pending = (await db.Database.GetPendingMigrationsAsync()).ToList();
    await db.Database.MigrateAsync();
    Console.WriteLine(pending.Count == 0 ? "Database is up to date." : $"Applied {pending.Count}: {string.Join(", ", pending)}");
    return;
}

// The first admin on a fresh database (admins can't sign up in the app):
// dotnet AanganMandi.Api.dll create-admin +919000054321 "Name"
if (Array.IndexOf(args, "create-admin") is var at and >= 0)
{
    if (at + 1 >= args.Length)
    {
        Console.WriteLine("Usage: create-admin <mobile number> [name]");
        return;
    }
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    Console.WriteLine(await AdminSetup.MakeAdminAsync(db, args[at + 1], at + 2 < args.Length ? args[at + 2] : null, default));
    return;
}

app.Services.ScheduleBackgroundJobs();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    await DevDataSeeder.SeedAsync(db);
}

app.UseExceptionHandler();
app.UseSerilogRequestLogging();
app.UseCors("App");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
