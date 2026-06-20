# 📐 Estructura del Proyecto Loginova

## Cambios Realizados

✅ **Workspace de VS Code**: Archivo `loginova.code-workspace` que abre ambos proyectos juntos  
✅ **Documentación centralizada**: README.md con toda la información  
✅ **Scripts de utilidad**: Para ejecutar y configurar el proyecto fácilmente  
✅ **Mejor navegación**: Etiquetas en el workspace para identificar cada proyecto  

---

## 📂 Estructura Final

```
new proyect/
│
├── 📄 loginova.code-workspace      ⭐ Abre ambos proyectos en VS Code
├── 📄 README.md                    📖 Documentación principal
├── 📄 ESTRUCTURA.md                (este archivo)
├── 📄 loginova_bd.sql              Database schema
│
├── 📁 Loginova/                    📱 Frontend Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── constants/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── themes/
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── pubspec.yaml
│   └── ...
│
├── 📁 LoginovaBackend/             🔌 Backend .NET
│   ├── 📄 README.md
│   └── 📁 LoginovaAPI/
│       ├── Controllers/
│       ├── Models/
│       ├── Data/
│       ├── Services/
│       ├── DTOs/
│       ├── Migrations/
│       ├── Program.cs
│       ├── LoginovaAPI.csproj
│       └── appsettings.json
│
└── 📁 scripts/                     🛠️ Scripts de utilidad
    ├── run-all.ps1               Ejecutar frontend + backend
    └── setup-dev.ps1             Configurar ambiente de desarrollo
```

---

## 🎯 Cómo Usar

### 1️⃣ **Abrir el Proyecto Completo**

**Opción A (Recomendado):** Doble clic en `loginova.code-workspace`

**Opción B:** Desde VS Code:
```
File → Open Workspace from File → loginova.code-workspace
```

### 2️⃣ **Configurar el Ambiente (Primera vez)**

```bash
cd "c:\Users\ozuna\new proyect"
.\scripts\setup-dev.ps1
```

### 3️⃣ **Ejecutar Ambos Proyectos**

```bash
.\scripts\run-all.ps1
```

O manualmente:

**Terminal 1 (Backend):**
```bash
cd LoginovaBackend/LoginovaAPI
dotnet run
```

**Terminal 2 (Frontend):**
```bash
cd Loginova
flutter run
```

---

## 🔄 Flujo de Trabajo Diario

```
┌─────────────────────────────────────┐
│ Abre loginova.code-workspace        │
│         en VS Code                  │
└──────────────┬──────────────────────┘
               │
        ┌──────▼─────────┬──────────────────┐
        │                │                  │
    ┌───▼────┐    ┌──────▼────┐    ┌──────▼────┐
    │Frontend │    │ Backend   │    │Database   │
    │(Flutter)│    │(.NET)     │    │(PostgreSQL)
    └────┬────┘    └──────┬────┘    └──────┬────┘
         │                │                │
    Flutter run   dotnet run       pgAdmin/psql
         │                │                │
         └────────────────┴────────────────┘
                    │
            ✅ Aplicación corriendo
```

---

## 📌 Ventajas de Esta Estructura

| Aspecto | Beneficio |
|--------|-----------|
| **Workspace único** | No necesitas abrir/cerrar VS Code múltiples veces |
| **Navegación rápida** | Cambia entre proyectos con un clic |
| **Scripts automáticos** | Compila/ejecuta todo sin escribir comandos largos |
| **Documentación centralizada** | Todo en un README.md en la raíz |
| **Escalabilidad** | Fácil agregar más servicios al workspace |
| **Control de versiones** | Ambos proyectos en el mismo repositorio Git |

---

## ⚡ Comandos Útiles Rápidos

```bash
# 📱 Frontend
cd Loginova && flutter clean && flutter pub get && flutter run

# 🔌 Backend
cd LoginovaBackend/LoginovaAPI && dotnet clean && dotnet run

# 🗄️ Base de datos (PostgreSQL)
psql -U postgres -f loginova_bd.sql

# 🏗️ Build para producción
cd Loginova && flutter build apk          # Android
cd Loginova && flutter build ios          # iOS
cd LoginovaBackend/LoginovaAPI && dotnet publish -c Release

# 🧹 Limpiar todo
cd Loginova && flutter clean
cd LoginovaBackend/LoginovaAPI && dotnet clean
```

---

## 📝 Configuración Importante

### 📍 API URL (Frontend)
Edit: `Loginova/lib/constants/app_constants.dart`
```dart
const String API_BASE_URL = 'http://localhost:5000';
```

### 🗄️ Base de Datos (Backend)
Edit: `LoginovaBackend/LoginovaAPI/appsettings.Development.json`
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=loginova;User Id=postgres;Password=tu_contraseña"
  }
}
```

---

## ❓ Preguntas Frecuentes

**P: ¿Debo eliminar las carpetas?**  
R: No, la estructura se mantiene igual. Solo agregué archivos de configuración para mejorar el workflow.

**P: ¿Puedo seguir usando git normalmente?**  
R: Sí, todo funciona exactamente igual. Ambos proyectos pueden tener sus propios repositorios.

**P: ¿Y si quiero abrir solo uno de los proyectos?**  
R: Abre la carpeta individual (`Loginova` o `LoginovaBackend`) directamente, o edita `loginova.code-workspace` para comentar una carpeta.

**P: ¿Cómo cambio el puerto del API?**  
R: Modifica `appsettings.json` en la sección `urls`.

---

## 🆘 Troubleshooting

| Error | Solución |
|-------|----------|
| "Flutter no encontrado" | Instala Flutter desde https://flutter.dev |
| ".NET no encontrado" | Instala .NET 10.0 SDK |
| "Puerto 5000 en uso" | Cambia puerto en `appsettings.json` |
| "Base de datos no existe" | Ejecuta `psql -U postgres -f loginova_bd.sql` |
| "Cambios no se recargan" | En Flutter usa `r` para reload, `R` para restart |

---

**Última actualización:** 2026-06-20  
**Creado por:** GitHub Copilot
