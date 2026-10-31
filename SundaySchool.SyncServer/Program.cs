using SundaySchool.SyncServer.Hubs;
using SundaySchool.SyncServer.Services;
using SundaySchool.SyncServer.Controllers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Configure port from environment or command line (default: 5050)
var portStr = Environment.GetEnvironmentVariable("PORT") ?? "5050";
if (!int.TryParse(portStr, out var port)) port = 5050;

builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 100 * 1024 * 1024; // 100 MB
    if (builder.Configuration.GetValue<bool>("BindLocalOnly")) options.ListenLocalhost(port);
    else options.ListenAnyIP(port);
});

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy
            .SetIsOriginAllowed(_ => true)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddControllers();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true, ValidIssuer = "SundaySchool.SyncServer",
        ValidateAudience = true, ValidAudience = "SundaySchool.FlutterClient",
        ValidateLifetime = true, ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(AuthController.GetJwtSecret(builder.Configuration))),
        ClockSkew = TimeSpan.FromMinutes(1),
    };
    options.Events = new JwtBearerEvents { OnMessageReceived = context =>
    {
        var token = context.Request.Query["access_token"];
        if (context.HttpContext.Request.Path.StartsWithSegments("/hubs/sync") && !string.IsNullOrEmpty(token))
            context.Token = token;
        return Task.CompletedTask;
    }, OnTokenValidated = async context =>
    {
        var raw = context.Principal?.FindFirst("sub")?.Value
            ?? context.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(raw, out var userId) || userId <= 0)
        {
            context.Fail("Session no longer identifies a user. Sign in again.");
            return;
        }
        var storage = context.HttpContext.RequestServices.GetRequiredService<StorageService>();
        if (!await storage.UserExistsAsync(userId))
            context.Fail("Session user no longer exists. Sign in again.");
    }};
});
builder.Services.AddAuthorization();
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
    options.MaximumReceiveMessageSize = 10 * 1024 * 1024;
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
});

builder.Services.AddSingleton<PostgresSchemaInitializer>();
builder.Services.AddSingleton<StorageService>();
builder.Services.AddSingleton<PersonChangeFeed>();
builder.Services.AddSingleton(sp => new DatabaseBackups.NativeBackupService(
    sp.GetRequiredService<PostgresSchemaInitializer>().ConnectionString, "SundaySchool",
    sp.GetRequiredService<ILogger<DatabaseBackups.NativeBackupService>>()));
builder.Services.AddHostedService(sp => sp.GetRequiredService<DatabaseBackups.NativeBackupService>());

var app = builder.Build();

// Initialize PostgreSQL schema and auto-import Betros_Bols.db if empty
using (var scope = app.Services.CreateScope())
{
    var schemaInitializer = scope.ServiceProvider.GetRequiredService<PostgresSchemaInitializer>();
    try
    {
        await schemaInitializer.InitializeAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Initial PostgreSQL initialization warning (will retry when DB is online).");
    }
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

var webRoot = Path.Combine(AppContext.BaseDirectory, "wwwroot");
if (Directory.Exists(webRoot))
{
    var fileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(webRoot);
    app.UseDefaultFiles(new DefaultFilesOptions
    {
        FileProvider = fileProvider
    });
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = fileProvider,
        OnPrepareResponse = ctx =>
        {
            if (ctx.File.Name.Equals("index.html", StringComparison.OrdinalIgnoreCase))
            {
                ctx.Context.Response.Headers.CacheControl = "no-cache, no-store, must-revalidate";
            }
            else
            {
                ctx.Context.Response.Headers.CacheControl = "public, max-age=31536000";
            }
        }
    });
}
app.Use(async (context, next) =>
{
    var started = System.Diagnostics.Stopwatch.StartNew();
    try { await next(context); }
    finally
    {
        if (context.Request.Path.StartsWithSegments("/api/storage") &&
            (started.ElapsedMilliseconds >= 1000 || context.Response.StatusCode >= 400))
            app.Logger.LogWarning("Storage request {Path}: {Status}, {ElapsedMs} ms",
                context.Request.Path, context.Response.StatusCode, started.ElapsedMilliseconds);
    }
});
app.MapControllers();
app.MapHub<SyncHub>("/hubs/sync");

app.MapGet("/health", async (StorageService storage, PostgresSchemaInitializer schema) =>
{
    var dbOk = await storage.CheckHealthAsync();
    if (!dbOk)
    {
        try
        {
            await schema.InitializeAsync();
            dbOk = await storage.CheckHealthAsync();
        }
        catch
        {
            // ignore
        }
    }

    return Results.Ok(new
    {
        ok = dbOk,
        status = dbOk ? "ok" : "degraded",
        service = "SundaySchool.SyncServer (.NET 8 + PostgreSQL + SignalR)",
        database = dbOk ? "connected" : "disconnected",
        engine = "PostgreSQL",
        sequenceId = storage.CurrentSequenceId,
        timestampUtc = DateTime.UtcNow,
    });
});

if (Directory.Exists(webRoot))
{
    var fileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(webRoot);
    app.MapFallbackToFile("index.html", new StaticFileOptions
    {
        FileProvider = fileProvider
    });
}

app.Run();
