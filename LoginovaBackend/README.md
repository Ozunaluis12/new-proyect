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

### 3. Conexión al API
Asegúrate de tener configurada la cadena de conexión en `appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=loginova_db;Username=postgres;Password=postgres"
  },
  "Jwt": {
    "Issuer": "LoginovaAPI",
    "Audience": "LoginovaClient",
    "Key": "LoginovaDevelopmentSecretKey2026ChangeMe"
  }
}
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

