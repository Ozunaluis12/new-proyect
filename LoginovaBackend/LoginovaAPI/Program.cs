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

// Monitoreo de errores en producción: sin "Sentry:Dsn" configurado el SDK
// queda deshabilitado (no-op) y no manda nada, así que es seguro dejarlo
// siempre presente en vez de condicionarlo a mano. Cuando se configure el
// DSN, empieza a reportar excepciones no controladas automáticamente,
// incluidas las que ya captura app.UseExceptionHandler más abajo.
builder.WebHost.UseSentry(options =>
{
    options.Dsn = builder.Configuration["Sentry:Dsn"];
    options.Environment = builder.Environment.EnvironmentName;
    options.TracesSampleRate = 0.2;
});

builder.Services.AddHttpContextAccessor();
// Multi-tenant: resuelve la empresa del request actual (claim "empresaId"
// del JWT). AppDbContext lo usa para los filtros de consulta globales que
// aíslan los datos de cada empresa entre sí.
builder.Services.AddScoped<ITenantContext, TenantContext>();
builder.Services.AddScoped<AuditoriaActionFilter>();
builder.Services.AddControllers(options =>
{
    // Registra el filtro de auditoría globalmente: todos los controllers quedan
    // auditados por defecto sin tener que decorarlos uno por uno. El filtro
    // redacta campos sensibles (password, token) antes de persistir el log.
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
builder.Services.AddScoped<SmtpEmailSender>();
builder.Services.AddScoped<ResendEmailSender>();
builder.Services.AddScoped<IEmailSender>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();

    // Resend viaja por HTTPS (443), que ninguna plataforma bloquea. SMTP
    // (587/465) sí lo bloquean Render y otros PaaS gratuitos, así que queda
    // solo como respaldo para desarrollo local, donde sí funciona.
    return !string.IsNullOrWhiteSpace(config["Resend:ApiKey"])
        ? sp.GetRequiredService<ResendEmailSender>()
        : sp.GetRequiredService<SmtpEmailSender>();
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    // Login y recuperación de contraseña son los blancos típicos de fuerza bruta.
    // Particionado por IP: AddFixedWindowLimiter (sin partición) comparte un
    // único contador global entre TODOS los clientes, así que el tráfico de
    // un usuario (o de pruebas) agota la cuota de todos los demás. Con
    // GetFixedWindowLimiter cada IP tiene su propio balde de 10/minuto.
    options.AddPolicy("auth", httpContext => RateLimitPartition.GetFixedWindowLimiter(
        partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        factory: _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 10,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
        }));
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
        // En desarrollo se permite cualquier origen para no fricción al probar
        // localmente contra distintos puertos/dispositivos; en producción se
        // restringe a la lista explícita (frontend Flutter web en Netlify) para
        // que no cualquier sitio pueda llamar a la API con las credenciales del usuario.
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

// Vigencia de membresía por empresa (multi-tenant) y de la cuenta
// individual: si la empresa del usuario autenticado está suspendida
// (Soporte) o su membresía ya venció, o si a ese usuario puntual lo
// desactivaron, se bloquea toda la API con un mensaje claro en vez de dejar
// que falle de forma confusa en cada endpoint. Se revisa en cada request
// (no solo al hacer login) para que una desactivación/suspensión tenga
// efecto inmediato y no haya que esperar a que expire el JWT (hasta 8h).
// /health queda exento para que el monitoreo de infraestructura siga
// viendo el servicio como "arriba".
app.Use(async (context, next) =>
{
    if (context.Request.Path != "/health" && context.User.Identity?.IsAuthenticated == true)
    {
        var dbContext = context.RequestServices.GetRequiredService<AppDbContext>();

        var userIdClaim = context.User.FindFirst("userId")?.Value;
        if (int.TryParse(userIdClaim, out var userId))
        {
            // IgnoreQueryFilters: es la única consulta de este middleware que
            // no depende de empresaId (se busca al propio usuario por su Id),
            // así que el filtro de tenant no debe interferir.
            var activo = await dbContext.Usuarios
                .IgnoreQueryFilters()
                .Where(u => u.Id == userId)
                .Select(u => (bool?)u.Activo)
                .FirstOrDefaultAsync();

            if (activo != true)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new
                {
                    mensaje = "Tu cuenta fue desactivada. Contacta a tu administrador o a soporte.",
                });
                return;
            }
        }

        var empresaIdClaim = context.User.FindFirst("empresaId")?.Value;
        if (int.TryParse(empresaIdClaim, out var empresaId))
        {
            var empresa = await dbContext.Empresas
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.Id == empresaId);

            if (empresa is null || !empresa.Activa || empresa.FechaFinMembresia < DateTime.UtcNow)
            {
                context.Response.StatusCode = StatusCodes.Status402PaymentRequired;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new
                {
                    mensaje = "Tu membresía está suspendida o vencida. Contacta a soporte para renovarla.",
                });
                return;
            }
        }
    }

    await next();
});

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
