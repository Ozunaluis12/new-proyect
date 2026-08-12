namespace LoginovaAPI.Utils;

/// <summary>
/// El correo es el identificador de login: si dos personas escriben el
/// mismo correo con distinta capitalización (o con espacios accidentales al
/// copiar/pegar) deben tratarse como la misma cuenta. Postgres compara texto
/// de forma sensible a mayúsculas por defecto, así que sin esto un usuario
/// registrado como "correo@x.com" no podía iniciar sesión escribiendo
/// "Correo@x.com". Se normaliza tanto al guardar el correo (alta/edición)
/// como al buscarlo (login, recuperación de contraseña, chequeos de
/// duplicado), para que la comparación nunca falle por eso.
/// </summary>
public static class CorreoUtils
{
    public static string Normalizar(string correo) => correo.Trim().ToLowerInvariant();
}
