using System.Security.Cryptography;

namespace LoginovaAPI.Services;

/// <summary>
/// Genera y verifica hashes de contraseña con PBKDF2 (salt aleatorio por
/// contraseña, 100,000 iteraciones, SHA-256). No existe ningún fallback a
/// texto plano: se quitó deliberadamente por seguridad, así que un hash con
/// un formato distinto a "pbkdf2$..." siempre se considera inválido.
/// </summary>
public class PasswordHasher
{
    private const int SaltSize = 16;
    private const int HashSize = 32;
    private const int Iterations = 100_000;

    /// <summary>
    /// Genera un salt aleatorio nuevo y devuelve el hash PBKDF2 de la contraseña
    /// en el formato "pbkdf2$iteraciones$salt$hash" (salt y hash en Base64).
    /// </summary>
    public string Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            HashSize);

        return $"pbkdf2${Iterations}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
    }

    /// <summary>
    /// Verifica una contraseña en texto plano contra un hash almacenado en
    /// formato "pbkdf2$iteraciones$salt$hash", recalculando el PBKDF2 con el
    /// mismo salt e iteraciones y comparando en tiempo constante para evitar
    /// ataques de temporización.
    /// </summary>
    public bool Verify(string password, string storedPassword)
    {
        if (!storedPassword.StartsWith("pbkdf2$", StringComparison.Ordinal))
        {
            // Ya no se acepta ningún formato distinto a pbkdf2$: no hay comparación
            // en texto plano. Una cuenta con un hash legado debe restablecer su
            // contraseña por el flujo de recuperación.
            return false;
        }

        var parts = storedPassword.Split('$');
        if (parts.Length != 4 || !int.TryParse(parts[1], out var iterations))
        {
            return false;
        }

        var salt = Convert.FromBase64String(parts[2]);
        var expectedHash = Convert.FromBase64String(parts[3]);
        var actualHash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            iterations,
            HashAlgorithmName.SHA256,
            expectedHash.Length);

        return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
    }
}
