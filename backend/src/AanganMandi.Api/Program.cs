using System.Text;
using System.Text.Json.Serialization;
using AanganMandi.Api.Auth;
using AanganMandi.Infrastructure;
using AanganMandi.Infrastructure.Persistence;
using Hangfire;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseSerilog((ctx, cfg) => cfg.ReadFrom.Configuration(ctx.Configuration).WriteTo.Console());

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
});
builder.Services.AddAuthorization();
// Development only: the Flutter web build runs on a random localhost port.
builder.Services.AddCors(o => o.AddPolicy("DevLocalhost", p => p
    .SetIsOriginAllowed(origin => new Uri(origin).IsLoopback)
    .AllowAnyHeader()
    .AllowAnyMethod()));
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

app.Services.ScheduleBackgroundJobs();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors("DevLocalhost");
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    await DevDataSeeder.SeedAsync(db);
}

app.UseExceptionHandler();
app.UseSerilogRequestLogging();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
