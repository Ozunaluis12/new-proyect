# 🚀 INICIO RÁPIDO - Nuevas Funcionalidades

## Pasos Inmediatos (5 minutos)

### 1. Actualizar pubspec.yaml
```bash
cd Loginova
flutter pub get
```

### 2. Configurar Constantes
Edita `lib/constants/app_constants.dart`:

```dart
static const String googleMapsApiKey = 'TU_API_KEY_AQUI'; // Reemplaza
static const String firebaseProjectId = 'loginova-proyecto'; // Reemplaza
```

### 3. Ejecutar Backend
```bash
cd LoginovaBackend/LoginovaAPI
dotnet run
```
✅ Base de datos ya migrada (verificado)
✅ Backend compila sin errores (verificado)

---

## Verificación Rápida

### Backend está activo?
```powershell
Invoke-WebRequest -Uri 'http://localhost:5105/api/auth/login' -Method Post | Select StatusCode
```
Debería retornar 400 (es normal sin credenciales)

### Base de datos tiene la tabla notificaciones?
```sql
SELECT * FROM notificaciones LIMIT 1;
```
Debería no dar error

---

## Usar en tu App

### Ejemplo 1: Obtener ubicación actual
```dart
import 'package:provider/provider.dart';
import 'lib/providers/location_provider.dart';

// En initState
final success = await context.read<LocationProvider>().getCurrentLocation();
if (success) {
  final loc = context.read<LocationProvider>().currentLocation;
  print('Ubicación: ${loc?.latitude}, ${loc?.longitude}');
}
```

### Ejemplo 2: Mostrar rastreo en pantalla
```dart
Consumer<LocationProvider>(
  builder: (context, locationProvider, _) {
    return Text(locationProvider.isTracking 
      ? '🔴 Rastreando' 
      : '⚫ Detenido'
    );
  },
)
```

### Ejemplo 3: Calcular ruta
```dart
import 'lib/providers/maps_provider.dart';
import 'lib/services/maps_service.dart';

final mapsProvider = context.read<MapsProvider>();
await mapsProvider.getRoute(
  origin: LatLng(latitude: 6.2442, longitude: -75.5812),
  destination: LatLng(latitude: 6.2500, longitude: -75.5900),
);

if (mapsProvider.currentRoute != null) {
  print('Distancia: ${mapsProvider.currentRoute!.distanceKm} km');
}
```

---

## Siguiente: Configurar APIs (15 minutos)

### Google Maps API Key
1. https://console.cloud.google.com/
2. Nuevo proyecto → "loginova"
3. APIs y servicios → Habilitar "Directions API" + "Geocoding API"
4. Credenciales → Crear API Key
5. Copiar en `lib/constants/app_constants.dart`

### Firebase
1. https://console.firebase.google.com/
2. Nuevo proyecto → "loginova"
3. Agregar app Flutter
4. Descargar `google-services.json` → `android/app/`
5. Descargar `GoogleService-Info.plist` → `ios/Runner/`
6. Actualizar Project ID en `app_constants.dart`

---

## Estructura de Carpetas Nueva

```
Loginova/
├── lib/
│   ├── providers/
│   │   ├── location_provider.dart ✨
│   │   ├── maps_provider.dart ✨
│   │   └── ...
│   ├── services/
│   │   ├── location_service.dart
│   │   ├── geocoding_service.dart ✨
│   │   ├── maps_service.dart ✨
│   │   ├── firebase_service.dart (mejorado)
│   │   └── ...
│   └── widgets/
│       ├── route_widgets.dart ✨
│       └── ...
```

---

## Documentación Completa
📖 Ver: `GUIA_USO_NUEVAS_FUNCIONALIDADES.md`

---

## Status ✅
- ✅ Backend compila sin errores
- ✅ BD migrada con tabla notificaciones
- ✅ Dependencias agregadas
- ✅ Providers creados
- ✅ Servicios implementados
- ⏳ Pendiente: API Keys externas
- ⏳ Pendiente: Testing en dispositivo

---

Siguientes pasos:
1. `flutter pub get`
2. Configurar Google Maps API Key
3. Configurar Firebase
4. Ejecutar: `flutter run`
