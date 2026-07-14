namespace LoginovaAPI.Services;

public class EvidenciaStorageService
{
    private readonly IWebHostEnvironment _environment;

    public EvidenciaStorageService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public string GetUploadsRootPath()
    {
        var webRootPath = _environment.WebRootPath;
        if (string.IsNullOrWhiteSpace(webRootPath))
        {
            webRootPath = Path.Combine(_environment.ContentRootPath, "wwwroot");
        }

        return Path.Combine(webRootPath, "uploads");
    }

    public string BuildRelativePath(int recogidaId, string fileName)
    {
        return $"uploads/evidencias/{recogidaId}/{fileName}".Replace('\\', '/');
    }

    public string BuildPublicUrl(HttpRequest request, string relativePath)
    {
        var normalizedPath = relativePath.Replace('\\', '/');
        return $"{request.Scheme}://{request.Host}/{normalizedPath}";
    }
}
