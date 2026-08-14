using LoginovaAPI.Utils;

namespace LoginovaAPI.Tests;

public class CorreoUtilsTests
{
    [Theory]
    [InlineData("Correo@X.com", "correo@x.com")]
    [InlineData("  correo@x.com  ", "correo@x.com")]
    [InlineData("CORREO@X.COM", "correo@x.com")]
    [InlineData("correo@x.com", "correo@x.com")]
    public void Normalizar_TrimsAndLowercases(string entrada, string esperado)
    {
        Assert.Equal(esperado, CorreoUtils.Normalizar(entrada));
    }

    [Fact]
    public void Normalizar_DifferentCasing_ProducesSameResult()
    {
        // Este es el escenario que arregló la migración "NormalizaCorreosAMinuscula":
        // dos formas de escribir el mismo correo deben normalizar igual para que
        // el login (que compara por igualdad exacta) no dependa de mayúsculas.
        Assert.Equal(
            CorreoUtils.Normalizar("Usuario@Empresa.com"),
            CorreoUtils.Normalizar("usuario@empresa.com"));
    }
}
