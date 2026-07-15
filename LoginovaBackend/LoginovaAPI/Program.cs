using System.Globalization;
using System.Text;
using LoginovaAPI.Data;
using LoginovaAPI.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Threading.RateLimiting;

// Fuerza cultura invariante ("." como separador decimal) en todos los hilos.
// Sin esto, el model binding de formularios (p. ej. montoCobrado en recogidas)
// interpreta los decimales según la configuración regional del servidor: en
// una cultura como es-CO, "12500.50" se lee como 1 250 050 y corrompe el monto.
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<AuditoriaActionFilter>();
builder.Services.AddControllers(options =>
{
    options.Filters.AddService<AuditoriaActionFilter>();
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection no esta configurado. Define el valor en variables de entorno o secrets locales.");
}

connectionString = NormalizeConnectionString(connectionString);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString)
        .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning)));

builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<PasswordHasher>();
builder.Services.AddScoped<AuditoriaService>();
builder.Services.AddScoped<NotificacionService>();
builder.Services.AddScoped<EvidenciaStorageService>();
builder.Services.AddScoped<PermisosService>();
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    // Login, registro y recuperación de contraseña son los blancos típicos de fuerza bruta.
    options.AddFixedWindowLimiter("auth", limiterOptions =>
    {
        limiterOptions.PermitLimit = 10;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueLimit = 0;
    });
});

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? [];

if (!builder.Environment.IsDevelopment() && allowedOrigins.Length == 0)
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins debe configurarse en entornos no Development.");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("LoginovaCors", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin()
                .AllowAnyHeader()
                .AllowAnyMethod();
            return;
        }

        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var jwt = builder.Configuration.GetSection("Jwt");
var jwtKey = jwt["Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException(
        "Jwt:Key no esta configurado. Define el valor en variables de entorno o secrets locales.");
}

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Aplica automáticamente las migraciones pendientes al iniciar. Simplifica el
// despliegue en plataformas gratuitas (Render, etc.) donde no siempre hay una
// terminal disponible para correr `dotnet ef database update` a mano.
using (var scope = app.Services.CreateScope())
{
    scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.Migrate();
}

// Render (y la mayoría de PaaS) terminan el TLS en su proxy y reenvían la
// petición al contenedor por HTTP plano. Sin esto, UseHttpsRedirection() no
// reconoce que la petición original ya era HTTPS.
var forwardedHeadersOptions = new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
};
forwardedHeadersOptions.KnownIPNetworks.Clear();
forwardedHeadersOptions.KnownProxies.Clear();
app.UseForwardedHeaders(forwardedHeadersOptions);

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    timestamp = DateTimeOffset.UtcNow
}));

app.MapGet("/openapi/v1.json", () => Results.Json(new
{
    openapi = "3.0.0",
    info = new
    {
        title = "Loginova API",
        version = "v1"
    },
    paths = new { }
}));

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseExceptionHandler(handler =>
{
    handler.Run(async context =>
    {
        var loggerFactory = context.RequestServices.GetRequiredService<ILoggerFactory>();
        var feature = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>();
        if (feature is not null)
        {
            loggerFactory.CreateLogger("GlobalExceptionHandler")
                .LogError(feature.Error, "Excepción no controlada en {Path}", context.Request.Path);
        }

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(new { mensaje = "Ocurrió un error interno. Intenta nuevamente." });
    });
});

app.UseCors("LoginovaCors");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

// Las evidencias viven fuera de wwwroot a propósito: solo se sirven a través de
// este endpoint autenticado, nunca como archivo estático público. El storage
// decide internamente si el archivo vive en Cloudflare R2 o en disco local.
app.MapGet("/uploads/{recogidaId:int}/{fileName}", async (int recogidaId, string fileName, EvidenciaStorageService storage) =>
{
    var resultado = await storage.AbrirAsync(recogidaId, fileName);
    if (resultado is null)
    {
        return Results.NotFound();
    }

    var (stream, contentType) = resultado.Value;
    return Results.Stream(stream, contentType);
}).RequireAuthorization();

app.MapControllers();

app.Run();

/// <summary>
/// Convierte una cadena de conexión en formato URI (postgres://usuario:clave@host:puerto/bd),
/// como la que entregan Render, Railway, Neon, Heroku, etc., al formato clave=valor que
/// espera Npgsql. Si la cadena ya viene en formato clave=valor, se devuelve sin cambios.
/// </summary>
static string NormalizeConnectionString(string raw)
{
    if (!raw.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) &&
        !raw.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
    {
        return raw;
    }

    var uri = new Uri(raw);
    var userInfo = uri.UserInfo.Split(':', 2);

    var builder = new NpgsqlConnectionStringBuilder
    {
        Host = uri.Host,
        Port = uri.Port > 0 ? uri.Port : 5432,
        Database = uri.AbsolutePath.TrimStart('/'),
        Username = Uri.UnescapeDataString(userInfo[0]),
        Password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty,
        SslMode = SslMode.Require,
    };

    return builder.ConnectionString;
}
