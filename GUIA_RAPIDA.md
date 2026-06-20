# 📱 LOGINOVA - Guía Rápida de Inicio

## 🚀 Estado Actual del Proyecto

Loginova es una plataforma logística profesional de código abierto para gestión de recogidas de paquetes. ✅ **VISTAS COMPLETAMENTE PROFESIONALIZADAS Y MEJORADAS**

### ✅ Completado en esta sesión:

**Interfaz de Usuario (UI/UX)**
- ✅ Tema profesional con paleta de colores corporativos
- ✅ Login Screen - Diseño moderno con validaciones mejoradas
- ✅ Register Screen - Formulario de registro profesional
- ✅ Forgot Password Screen - Recuperación de contraseña elegante
- ✅ Dashboard - Estadísticas visuales con Cards interactivas
- ✅ Recogidas Screen - Lista profesional con filtros por estado
- ✅ Crear Recogida - Formulario completo y validado
- ✅ Detalle Recogida - Vista completa de información
- ✅ Perfil Screen - Información de usuario y configuración

**Features Principales**
- ✅ Autenticación JWT (backend ready)
- ✅ State Management con Provider (robusto)
- ✅ CRUD Operations para recogidas
- ✅ Validaciones de formularios avanzadas
- ✅ Manejo de errores profesional
- ✅ Loading states y feedback visual
- ✅ Navegación intuitiva con Bottom Navigation

---

## 📦 Estructura del Proyecto

```
Loginova/
├── lib/
│   ├── main.dart                 # Punto de entrada con tema
│   ├── themes/
│   │   └── app_theme.dart       # Tema profesional (colores, estilos)
│   ├── screens/
│   │   ├── login_screen.dart    # ✅ Login profesional
│   │   ├── register_screen.dart # ✅ Registro mejorado
│   │   ├── forgot_password_screen.dart # ✅ Recuperación de contraseña
│   │   ├── home_screen.dart     # ✅ Dashboard con stats
│   │   ├── recogidas_screen.dart # ✅ Lista con filtros
│   │   ├── crear_recogida_screen.dart # ✅ Crear nueva recogida
│   │   ├── detalle_recogida_screen.dart # ✅ Vista detallada
│   │   └── perfil_screen.dart   # ✅ Perfil de usuario
│   ├── providers/
│   │   ├── auth_provider.dart       # Autenticación
│   │   ├── recogida_provider.dart   # Gestión de recogidas
│   │   └── usuario_provider.dart    # Datos de usuario
│   ├── services/
│   │   ├── api_service.dart         # Configuración API
│   │   ├── auth_service.dart        # Servicio de autenticación
│   │   ├── recogida_service.dart    # CRUD de recogidas
│   │   ├── cliente_service.dart     # CRUD de clientes
│   │   └── evidencia_service.dart   # Gestión de evidencias
│   ├── models/
│   │   ├── usuario.dart             # Modelo de usuario
│   │   ├── cliente.dart             # Modelo de cliente
│   │   ├── recogida.dart            # Modelo de recogida
│   │   └── evidencia.dart           # Modelo de evidencia
│   ├── routes/
│   │   └── app_routes.dart          # Definición de rutas
│   ├── constants/
│   │   └── app_constants.dart       # Constantes globales
│   ├── utils/                       # Utilidades
│   └── widgets/                     # Widgets reutilizables
├── android/                         # Código Android
├── ios/                            # Código iOS
├── web/                            # Código Web
├── pubspec.yaml                    # Dependencias
└── README.md                       # Este archivo
```

---

## 🛠️ Instalación y Configuración

### Requisitos Previos
- Flutter SDK ^3.12.0
- Dart ^3.12.0
- Editor: VS Code o Android Studio
- Backend ASP.NET Core ejecutándose en `http://localhost:5105`

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd Loginova
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar la URL del backend**
   - Editar: `lib/services/api_service.dart`
   - Cambiar `baseUrl` según tu servidor

4. **Ejecutar la aplicación**
   ```bash
   # En dispositivo conectado
   flutter run
   
   # En emulador
   flutter run -d <EMULATOR_ID>
   
   # En web
   flutter run -d web-server
   ```

---

## 🎨 Tema y Colores

Todos los colores y estilos están centralizados en `themes/app_theme.dart`:

```dart
// Colores Corporativos
Primary: #1E88E5 (Azul profesional)
Secondary: #FFA726 (Naranja)
Success: #4CAF50 (Verde)
Error: #F44336 (Rojo)
Warning: #FFC107 (Amarillo)
```

Para cambiar el tema global, edita `LoginovaColors` en `app_theme.dart`.

---

## 📱 Pantallas Principales

### 1. **Login Screen** 
- Email y contraseña validados
- Visibilidad de contraseña
- Links a registro y recuperación
- Loading state profesional

### 2. **Dashboard (Home)**
- Estadísticas en tiempo real
- Contadores de recogidas (Total, Pendientes, En Progreso, Completadas)
- Accesos rápidos a funciones principales
- Información de bienvenida personalizada

### 3. **Recogidas**
- Lista de todas las recogidas
- Filtros por estado (Pendiente, Asignada, En Ruta, Recogida, Cancelada)
- Visualización de estado con colores y iconos
- Opciones de ver detalle y eliminar

### 4. **Crear Recogida**
- Datos del cliente (Nombre, Teléfono, Dirección, Ciudad)
- Información de recogida (Paquetes, Observaciones)
- Validaciones completas
- Guardado exitoso con feedback

### 5. **Detalle Recogida**
- Vista completa de la recogida
- Información de cliente y operador
- Cantidad de paquetes
- Observaciones y evidencias
- Botones para añadir evidencia o volver

### 6. **Perfil**
- Información personal del usuario
- Rol y contacto
- Opciones de configuración
- Cerrar sesión

---

## 🔐 Autenticación y Seguridad

### JWT Token
- Los tokens se guardan en `SharedPreferences`
- Se envían automáticamente en cada request
- Se validan en el backend

### Flujo de Autenticación
```
Login → Backend valida → Retorna JWT + Usuario
                    ↓
          GuardaToken en SharedPreferences
                    ↓
          Carga sesión al iniciar app
                    ↓
          Navega a Home si está autenticado
```

---

## 🚀 Próximos Pasos (Pendiente)

### 1. **Backend PostgreSQL**
- [ ] Configurar base de datos PostgreSQL
- [ ] Crear tablas según documentación
- [ ] Configurar Entity Framework Core

### 2. **Migraciones**
- [ ] Crear migraciones en EF Core
- [ ] Aplicar migraciones a la BD
- [ ] Validar integridad de datos

### 3. **API Endpoints Reales**
- [ ] Implementar AuthController
- [ ] Implementar UsuariosController
- [ ] Implementar ClientesController
- [ ] Implementar RecogidasController
- [ ] Implementar EvidenciasController

### 4. **Integraciones Futuras**
- [ ] Firebase Storage para imágenes
- [ ] Google Maps API para rutas
- [ ] Notificaciones Push
- [ ] Reportes PDF
- [ ] Estadísticas en tiempo real

### 5. **Testing**
- [ ] Unit tests para servicios
- [ ] Widget tests para pantallas
- [ ] Integration tests completos

### 6. **Producción**
- [ ] Build APK para Android
- [ ] Build iOS
- [ ] Hosting en App Stores
- [ ] Monitoreo y logging
- [ ] CI/CD pipeline

---

## 📚 Estructura de Datos

### Usuario
```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "correo": "juan@example.com",
  "rol": "Operador"
}
```

### Cliente
```json
{
  "id": 1,
  "nombre": "Empresa XYZ",
  "telefono": "+34 123 456 789",
  "direccion": "Calle Principal 123",
  "ciudad": "Madrid"
}
```

### Recogida
```json
{
  "id": 1,
  "clienteId": 1,
  "usuarioId": 1,
  "estado": "Pendiente",
  "cantidadPaquetes": 5,
  "observaciones": "Frágil",
  "evidencias": ["url1", "url2"]
}
```

---

## 🐛 Troubleshooting

### Error: "No se puede conectar al backend"
- Verificar que el servidor ASP.NET está corriendo
- Revisar URL en `api_service.dart`
- Verificar puerto (por defecto: 5105)

### Error: "Invalid token"
- Limpiar SharedPreferences: `flutter clean`
- Hacer login nuevamente
- Verificar credenciales

### Error: "Widget not found"
- Ejecutar `flutter pub get`
- Limpiar build: `flutter clean`
- Reconstruir: `flutter pub get && flutter run`

---

## 📖 Recursos Útiles

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 👥 Contribuir

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo licencia MIT.

---

**¡Gracias por usar Loginova! 🚀**

Para soporte, contacta al equipo de desarrollo.
