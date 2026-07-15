namespace LoginovaAPI.Services;

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

    public EvidenciaStorageService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    /// <summary>
    /// Carpeta física donde se guardan las evidencias. Vive fuera de wwwroot
    /// a propósito: los archivos solo deben ser accesibles a través del
    /// endpoint autenticado /uploads, nunca servidos como archivo estático.
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
