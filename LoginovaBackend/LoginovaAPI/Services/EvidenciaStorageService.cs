using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;

namespace LoginovaAPI.Services;

/// <summary>
/// Guarda y sirve las evidencias (fotos). Si hay credenciales de Cloudflare R2
/// configuradas, sube/lee los archivos ahí (persisten entre despliegues y
/// reinicios). Si no, usa disco local como respaldo simple para desarrollo,
/// sabiendo que en plataformas como Render el disco es efímero.
/// </summary>
public class EvidenciaStorageService
{
    private const long TamanoMaximoBytes = 8 * 1024 * 1024; // 8 MB

    private static readonly Dictionary<string, string> ExtensionesPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        [".jpg"] = "image/jpeg",
        [".jpeg"] = "image/jpeg",
        [".png"] = "image/png",
        [".webp"] = "image/webp",
        [".heic"] = "image/heic",
        [".heif"] = "image/heif",
    };

    private readonly IWebHostEnvironment _environment;
    private readonly IAmazonS3? _s3Client;
    private readonly string? _bucketName;

    public EvidenciaStorageService(IWebHostEnvironment environment, IConfiguration configuration)
    {
        _environment = environment;

        var accountId = configuration["R2:AccountId"];
        var accessKey = configuration["R2:AccessKeyId"];
        var secretKey = configuration["R2:SecretAccessKey"];
        var bucketName = configuration["R2:BucketName"];

        if (!string.IsNullOrWhiteSpace(accountId) &&
            !string.IsNullOrWhiteSpace(accessKey) &&
            !string.IsNullOrWhiteSpace(secretKey) &&
            !string.IsNullOrWhiteSpace(bucketName))
        {
            _bucketName = bucketName;
            _s3Client = new AmazonS3Client(accessKey, secretKey, new AmazonS3Config
            {
                ServiceURL = $"https://{accountId}.r2.cloudflarestorage.com",
                ForcePathStyle = true,
                AuthenticationRegion = "auto",
                // El AWS SDK v4 firma los PutObject con un checksum "trailer"
                // (STREAMING-...-PAYLOAD-TRAILER) por defecto, que Cloudflare
                // R2 todavía no soporta. WHEN_REQUIRED vuelve al modo clásico,
                // compatible con R2 (y con S3 real, que sigue soportándolo).
                RequestChecksumCalculation = RequestChecksumCalculation.WHEN_REQUIRED,
                ResponseChecksumValidation = ResponseChecksumValidation.WHEN_REQUIRED,
            });
        }
    }

    /// <summary>Indica si el almacenamiento persistente (R2) está configurado.</summary>
    public bool UsaAlmacenamientoPersistente => _s3Client is not null;

    /// <summary>
    /// Carpeta física donde se guardan las evidencias cuando no hay R2 configurado.
    /// Vive fuera de wwwroot a propósito: los archivos solo deben ser accesibles a
    /// través del endpoint autenticado /uploads, nunca servidos como archivo estático.
    /// </summary>
    public string GetUploadsRootPath()
    {
        return Path.Combine(_environment.ContentRootPath, "App_Data", "uploads");
    }

    public string BuildRelativePath(int recogidaId, string fileName)
    {
        return $"{recogidaId}/{fileName}";
    }

    public string BuildPublicUrl(HttpRequest request, string relativePath)
    {
        var normalizedPath = relativePath.Replace('\\', '/');
        return $"{request.Scheme}://{request.Host}/uploads/{normalizedPath}";
    }

    /// <summary>Guarda el contenido de una evidencia bajo la clave recogidaId/fileName.</summary>
    public async Task GuardarAsync(int recogidaId, string fileName, Stream contenido, string? contentType)
    {
        var key = BuildRelativePath(recogidaId, fileName);

        if (_s3Client is not null)
        {
            // Se bufferiza completo en memoria (las evidencias están limitadas a
            // pocos MB) para que el SDK conozca el tamaño exacto de entrada y no
            // recurra a "chunked streaming" con checksum trailer, un modo que
            // Cloudflare R2 todavía no soporta (STREAMING-...-PAYLOAD-TRAILER
            // not implemented) y que sí usa por defecto con streams sin tamaño
            // fijo conocido de antemano.
            await using var buffer = new MemoryStream();
            await contenido.CopyToAsync(buffer);
            buffer.Position = 0;

            await _s3Client.PutObjectAsync(new PutObjectRequest
            {
                BucketName = _bucketName,
                Key = key,
                InputStream = buffer,
                ContentType = string.IsNullOrWhiteSpace(contentType) ? ObtenerContentType(Path.GetExtension(fileName)) : contentType,
                AutoCloseStream = false,
                DisablePayloadSigning = true,
            });
            return;
        }

        var uploadsRoot = GetUploadsRootPath();
        var carpeta = Path.Combine(uploadsRoot, recogidaId.ToString());
        Directory.CreateDirectory(carpeta);
        var fullPath = Path.Combine(carpeta, fileName);

        await using var destino = new FileStream(fullPath, FileMode.Create);
        await contenido.CopyToAsync(destino);
    }

    /// <summary>
    /// Abre el contenido de una evidencia guardada. Devuelve null si no existe.
    /// </summary>
    public async Task<(Stream Stream, string ContentType)?> AbrirAsync(int recogidaId, string fileName)
    {
        var key = BuildRelativePath(recogidaId, fileName);

        if (_s3Client is not null)
        {
            try
            {
                var respuesta = await _s3Client.GetObjectAsync(_bucketName, key);
                var contentType = string.IsNullOrWhiteSpace(respuesta.Headers.ContentType)
                    ? ObtenerContentType(Path.GetExtension(fileName))
                    : respuesta.Headers.ContentType;
                return (respuesta.ResponseStream, contentType);
            }
            catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return null;
            }
        }

        var root = Path.GetFullPath(GetUploadsRootPath());
        var requestedPath = Path.GetFullPath(Path.Combine(root, key));

        if (!requestedPath.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) ||
            !File.Exists(requestedPath))
        {
            return null;
        }

        Stream stream = new FileStream(requestedPath, FileMode.Open, FileAccess.Read);
        return (stream, ObtenerContentType(Path.GetExtension(requestedPath)));
    }

    /// <summary>
    /// Valida que el archivo subido sea una imagen razonable: extensión y
    /// content-type dentro de la lista blanca, y tamaño acotado.
    /// </summary>
    public bool EsImagenValida(IFormFile archivo, out string? error)
    {
        if (archivo.Length <= 0)
        {
            error = "El archivo está vacío";
            return false;
        }

        if (archivo.Length > TamanoMaximoBytes)
        {
            error = $"El archivo supera el tamaño máximo permitido ({TamanoMaximoBytes / (1024 * 1024)} MB)";
            return false;
        }

        var extension = Path.GetExtension(archivo.FileName);
        if (string.IsNullOrWhiteSpace(extension) || !ExtensionesPermitidas.TryGetValue(extension, out var contentTypeEsperado))
        {
            error = "Tipo de archivo no permitido. Usa jpg, png, webp o heic";
            return false;
        }

        if (!string.IsNullOrWhiteSpace(archivo.ContentType) &&
            !archivo.ContentType.Equals(contentTypeEsperado, StringComparison.OrdinalIgnoreCase) &&
            !archivo.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            error = "El contenido del archivo no corresponde a una imagen";
            return false;
        }

        error = null;
        return true;
    }

    /// <summary>
    /// Genera un nombre de archivo seguro (aleatorio) que conserva únicamente
    /// la extensión validada, sin usar nunca el nombre original del cliente.
    /// </summary>
    public string GenerarNombreArchivo(IFormFile archivo)
    {
        var extension = Path.GetExtension(archivo.FileName);
        return $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
    }

    public static string ObtenerContentType(string extension)
    {
        return ExtensionesPermitidas.TryGetValue(extension, out var contentType)
            ? contentType
            : "application/octet-stream";
    }
}
