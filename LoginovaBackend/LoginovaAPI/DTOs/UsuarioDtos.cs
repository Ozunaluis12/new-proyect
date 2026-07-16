using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>
/// Datos públicos de un usuario devueltos por la API. Nunca incluye Password/hash;
/// Permisos ya viene deserializado desde Usuario.PermisosJson.
/// </summary>
public record UsuarioResponse(
    int Id,
    string Nombre,
    string Correo,
    string Rol,
    List<string> Permisos);

/// <summary>
/// Datos para crear un usuario. Password llega en claro (se hashea antes de
/// guardar) y Permisos es la lista de nombres de permisos a asignar, independiente
/// del Rol elegido.
/// </summary>
public record UsuarioCreateRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    [Required, MinLength(8)] string Password,
    [Required] string Rol,
    List<string>? Permisos);

/// <summary>Datos para actualizar un usuario existente. Password es opcional: si viene null/vacío, no se cambia la contraseña actual.</summary>
public record UsuarioUpdateRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    string? Password,
    [Required] string Rol,
    List<string>? Permisos);
