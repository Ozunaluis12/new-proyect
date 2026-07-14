# LoginovaBackend

## Buenas prácticas para el backend

### 1. Mantén tu código organizado
- El backend debe vivir en `LoginovaBackend/LoginovaAPI/`
- No muevas archivos de .NET al frontend
- Usa carpetas claras: `Controllers/`, `Models/`, `Data/`, `Services/`

### 2. Configuración por entorno
- Usa `appsettings.json` para valores de producción
- Usa `appsettings.Development.json` para valores locales
- No subas contraseñas reales al repositorio

### 3. Configuración requerida (entorno)
El backend ahora exige valores sensibles por variables de entorno o user-secrets.

PowerShell (ejemplo local):
```powershell
$env:ConnectionStrings__DefaultConnection = "Host=localhost;Port=5432;Database=loginova_bd;Username=postgres;Password=TU_PASSWORD"
$env:Jwt__Issuer = "LoginovaAPI"
$env:Jwt__Audience = "LoginovaClient"
$env:Jwt__Key = "TU_JWT_KEY_LARGA_Y_SEGURA"

# CORS (si no está en appsettings)
$env:Cors__AllowedOrigins__0 = "http://localhost:3000"
$env:Cors__AllowedOrigins__1 = "http://localhost:5105"

# Firebase FCM (elige una opción)
$env:Firebase__ProjectId = "tu-proyecto-firebase"
$env:Firebase__ServiceAccountPath = "C:\ruta\service-account.json"
# o
# $env:Firebase__ServiceAccountJson = '{...json de service account...}'
# o
# $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\ruta\service-account.json"
```

### 4. Ejecutar backend
```powershell
cd "c:\Users\ozuna\new proyect\LoginovaBackend\LoginovaAPI"
dotnet restore
dotnet run
```

### 5. Buenas prácticas de desarrollo
- Usa `dotnet restore` solo cuando cambies paquetes
- Usa `dotnet run` para ejecutar en desarrollo
- Usa `dotnet watch run` si quieres ver cambios automáticos
- Mantén `Program.cs` limpio con solo configuración de servicios y middleware

### 6. Pruebas básicas
- Ejecuta el API y prueba en el navegador `https://localhost:7248` o `http://localhost:5105`
- Verifica que las rutas de controllers respondan
- Asegura que el frontend use la misma URL base del API

### 7. Documentación útil
- Mantén este README actualizado con los comandos principales
- Guarda notas si cambias puertos o credenciales
- Usa la carpeta raíz para documentación general del proyecto

