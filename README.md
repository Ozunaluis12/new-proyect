# Loginova - Aplicación de Logística y Recolección de Envíos

Este es un monorepo que contiene tanto el frontend (Flutter) como el backend (.NET).

## 📁 Estructura del Proyecto

```
new proyect/
├── Loginova/              # 📱 Frontend Flutter
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── LoginovaBackend/       # 🔌 Backend .NET
│   └── LoginovaAPI/
│       ├── Controllers/
│       ├── Models/
│       └── LoginovaAPI.csproj
└── loginova.code-workspace
```

## 🚀 Inicio Rápido

### 1. Abrir el Workspace
Abre el archivo `loginova.code-workspace` en VS Code para cargar ambos proyectos simultáneamente.

### 2. Frontend (Flutter)

```bash
cd Loginova

# Obtener dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run

# Compilar para Android
flutter build apk

# Compilar para iOS
flutter build ios
```

**Dependencias principales:**
- `provider`: Gestión de estado
- `http`: Peticiones HTTP
- `image_picker`: Seleccionar imágenes
- `shared_preferences`: Almacenamiento local

### 3. Backend (.NET)

```bash
cd LoginovaBackend/LoginovaAPI

# Restaurar paquetes
dotnet restore

# Ejecutar en desarrollo
dotnet run

# Compilar
dotnet build

# Publicar
dotnet publish -c Release
```

**Tecnologías:**
- .NET 10.0
- Entity Framework Core
- PostgreSQL (Npgsql)
- JWT Authentication

## 🔗 Conexión Frontend-Backend

Asegúrate de configurar la URL base del API en el frontend:

**En Loginova/lib/services/** (crear si no existe):
```dart
const String API_BASE_URL = 'http://localhost:5000'; // Ajusta el puerto
```

## 📝 Variables de Entorno

### Backend (.NET)
Configura en `LoginovaBackend/LoginovaAPI/appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=loginova;User Id=postgres;Password=tu_password"
  }
}
```

### Base de Datos
Ejecuta el script SQL para crear la base de datos:
```bash
psql -U postgres -f loginova_bd.sql
```

## 💡 Consejos para Trabajar

1. **Terminal dividida en VS Code:**
   - Abre una terminal para el frontend y otra para el backend
   - Puedes cambiar entre pestañas fácilmente

2. **Debug simultáneo:**
   - Instala extensiones de debug para ambos lenguajes
   - Usa breakpoints en ambos lados

3. **Cambios en tiempo real:**
   - Flutter hot reload funciona excelente
   - .NET vigila cambios con `dotnet watch run`

## 📦 Requisitos Previos

- Flutter SDK 3.12+
- .NET 10.0 SDK
- PostgreSQL 12+
- Android Studio / Xcode (para compilación nativa)

## 🧠 Buenas prácticas para el proyecto

- Mantén la raíz del proyecto con las dos carpetas separadas: `Loginova/` y `LoginovaBackend/`
- No mezcles archivos de Flutter con archivos de .NET en la misma carpeta
- Usa `loginova.code-workspace` para abrir todo el proyecto a la vez
- Usa tareas de VS Code para ejecutar frontend y backend sin cambiar carpetas
- Documenta los comandos principales en `README.md`
- Controla el código con Git desde la raíz del proyecto

## ⚙️ Uso de VS Code Tasks

En VS Code puedes ejecutar estas tareas fácilmente con:
1. `Terminal` → `Run Task...`
2. Elegir:
   - `Flutter: pub get`
   - `Flutter: Run`
   - `Flutter: Build APK`
   - `Backend: dotnet restore`
   - `Backend: Run`

## 🛠️ Troubleshooting

| Problema | Solución |
|----------|----------|
| Frontend no conecta con API | Verifica la URL base en constants y que el backend está corriendo |
| Error de puerto ocupado | Cambia el puerto en `appsettings.json` |
| Errores de Flutter | Ejecuta `flutter clean` y `flutter pub get` |
| EF Core migrations | Ejecuta `dotnet ef database update` |

## 📧 Contacto y Soporte

Para dudas o reportar problemas, consulta la documentación en cada carpeta.

---

**Última actualización:** 2026-06-20
