using LoginovaAPI.Services;

namespace LoginovaAPI.Tests;

public class PasswordHasherTests
{
    [Fact]
    public void Hash_ThenVerify_WithCorrectPassword_ReturnsTrue()
    {
        // Arrange
        var hasher = new PasswordHasher();
        const string password = "Admin123!";

        // Act
        var hashed = hasher.Hash(password);
        var isValid = hasher.Verify(password, hashed);

        // Assert
        Assert.True(isValid);
        Assert.StartsWith("pbkdf2$", hashed, StringComparison.Ordinal);
    }

    [Fact]
    public void Verify_WithWrongPassword_ReturnsFalse()
    {
        // Arrange
        var hasher = new PasswordHasher();
        const string password = "Admin123!";
        var hashed = hasher.Hash(password);

        // Act
        var isValid = hasher.Verify("Admin123?", hashed);

        // Assert
        Assert.False(isValid);
    }

    [Fact]
    public void Verify_WithLegacyPlainTextHash_AlwaysReturnsFalse()
    {
        // Arrange: el fallback a texto plano se quitó deliberadamente por
        // seguridad (ver comentario de PasswordHasher). Un hash legado sin el
        // prefijo "pbkdf2$" ya no debe validar, ni siquiera con la contraseña
        // correcta; esa cuenta debe pasar por el flujo de recuperación.
        var hasher = new PasswordHasher();

        // Act
        var samePassword = hasher.Verify("legacy-pass", "legacy-pass");
        var otherPassword = hasher.Verify("other", "legacy-pass");

        // Assert
        Assert.False(samePassword);
        Assert.False(otherPassword);
    }
}
