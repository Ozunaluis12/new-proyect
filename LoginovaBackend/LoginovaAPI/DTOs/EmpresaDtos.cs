using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Datos para crear una empresa nueva junto con su primer Administrador.</summary>
public record CrearEmpresaRequest(
    [Required] string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    [Required] DateTime FechaInicioMembresia,
    [Required] DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    [Required] string AdminNombre,
    [Required, EmailAddress] string AdminCorreo,
    [Required, MinLength(8)] string AdminPassword);

/// <summary>Datos para actualizar una empresa existente (no toca su administrador).</summary>
public record ActualizarEmpresaRequest(
    [Required] string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    [Required] DateTime FechaInicioMembresia,
    [Required] DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas);

/// <summary>Datos de una empresa devueltos por la API, con el estado de membresía ya calculado.</summary>
public record EmpresaResponse(
    int Id,
    string NombreEmpresa,
    string? NombreContacto,
    string? TelefonoContacto,
    string? CorreoContacto,
    DateTime FechaInicioMembresia,
    DateTime FechaFinMembresia,
    decimal? MontoMembresia,
    string? CicloPago,
    string? Notas,
    bool Activa,
    DateTime? UltimoRecordatorioEnviado,
    DateTime FechaCreacion,
    /// <summary>"Suspendida" (Activa=false), "Vencida", "PorVencer" (7 días o menos) o "Vigente".</summary>
    string EstadoMembresia,
    /// <summary>Días restantes hasta el vencimiento; negativo si ya venció.</summary>
    int DiasParaVencimiento);

/// <summary>Nuevo conjunto de permisos para un usuario, usado por Soporte al entrar a resolver un caso.</summary>
public record ActualizarPermisosRequest(List<string>? Permisos);

/// <summary>
/// Panorama rápido de una empresa para que Soporte pueda diagnosticar un caso
/// sin tener que pedirle capturas de pantalla al cliente: cuánta gente y
/// actividad tiene, y cuándo fue la última vez que se usó de verdad.
/// </summary>
public record ResumenSoporteEmpresaResponse(
    int TotalUsuarios,
    int TotalClientes,
    int TotalRecogidas,
    int RecogidasPendientes,
    int TotalIngresos,
    decimal MontoTotalIngresos,
    DateTime? UltimaRecogida);

/// <summary>Nombre de la propia empresa del usuario autenticado (para mostrarlo en la app, p. ej. en el botón de contactar soporte).</summary>
public record MiEmpresaResponse(int Id, string NombreEmpresa);

/// <summary>
/// Contraseña temporal generada para un usuario que quedó bloqueado. Se
/// devuelve una única vez en la respuesta (no queda guardada en claro en
/// ningún lado): Soporte debe comunicársela al cliente para que la use y
/// la cambie de inmediato.
/// </summary>
public record RestablecerPasswordResponse(string PasswordTemporal);

/// <summary>
/// Panorama agregado de todas las empresas para el Panel de Soporte: cuántas
/// hay en cada estado de membresía, cuánto ingreso mensual recurrente
/// representan las activas, y cuántas llevan tiempo sin actividad real
/// (posible señal de riesgo de cancelación).
/// </summary>
public record DashboardSoporteResponse(
    int TotalEmpresas,
    int EmpresasActivas,
    int EmpresasSuspendidas,
    int EmpresasPorVencer,
    int EmpresasVencidas,
    decimal IngresoMensualEstimado,
    int EmpresasSinActividadReciente);

/// <summary>Contenido de una nueva nota de la bitácora de soporte de una empresa.</summary>
public record CrearNotaSoporteRequest([Required] string Contenido);

/// <summary>Una entrada de la bitácora de soporte de una empresa.</summary>
public record NotaSoporteResponse(
    int Id,
    string Contenido,
    string CreadoPorNombre,
    DateTime FechaCreacion);

/// <summary>Datos para crear una nueva cuenta de Soporte (miembro del equipo interno).</summary>
public record CrearSoporteUsuarioRequest(
    [Required] string Nombre,
    [Required, EmailAddress] string Correo,
    [Required, MinLength(8)] string Password);

/// <summary>Activa o desactiva el acceso de un usuario puntual, sin afectar al resto de la empresa.</summary>
public record CambiarEstadoUsuarioRequest(bool Activo);

/// <summary>
/// Resultado de buscar a qué empresa pertenece un correo. Soporte lo usa
/// cuando un cliente escribe dando solo su correo, sin decir de qué
/// empresa es.
/// </summary>
public record BuscarUsuarioResponse(
    int Id,
    string Nombre,
    string Correo,
    string Rol,
    bool Activo,
    int? EmpresaId,
    string? NombreEmpresa);

/// <summary>Un pago/renovación de membresía registrado para una empresa.</summary>
public record PagoMembresiaResponse(
    int Id,
    decimal Monto,
    string? CicloPago,
    DateTime FechaPago,
    DateTime? PeriodoDesde,
    DateTime? PeriodoHasta,
    string? Notas,
    string RegistradoPorNombre);

/// <summary>Datos para registrar un nuevo pago/renovación de membresía.</summary>
public record CrearPagoMembresiaRequest(
    [Required] decimal Monto,
    string? CicloPago,
    DateTime? PeriodoDesde,
    DateTime? PeriodoHasta,
    string? Notas);

/// <summary>Plantillas de mensaje de WhatsApp para el recordatorio de vencimiento, editables por Soporte. Placeholders: {contacto}, {empresa}, {fecha}.</summary>
public record ConfiguracionSoporteResponse(
    string PlantillaRecordatorioVigente,
    string PlantillaRecordatorioVencida);

/// <summary>Nuevas plantillas de mensaje de WhatsApp.</summary>
public record ActualizarConfiguracionSoporteRequest(
    [Required] string PlantillaRecordatorioVigente,
    [Required] string PlantillaRecordatorioVencida);
