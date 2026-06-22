# 📍 Guía de Uso - Nuevas Funcionalidades Loginova

## 1. Posición Real-time (LocationService & LocationProvider)

### Iniciar rastreo de ubicación

En tu screen o widget:

```dart
import 'package:provider/provider.dart';
import 'lib/providers/location_provider.dart';

@override
void initState() {
  super.initState();
  // Inicia rastreo cuando entra en la pantalla
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<LocationProvider>().startTracking();
  });
}

@override
void dispose() {
  // Detiene rastreo al salir
  context.read<LocationProvider>().stopTracking();
  super.dispose();
}
```

### Escuchar cambios de ubicación

```dart
Consumer<LocationProvider>(
  builder: (context, locationProvider, child) {
    return Text(
      locationProvider.isTracking 
        ? 'Rastreando: ${locationProvider.currentLocation?.latitude}'
        : 'No rastreando'
    );
  },
)
```

### Obtener ubicación actual (una sola vez)

```dart
final success = await context.read<LocationProvider>().getCurrentLocation();
if (success) {
  final location = context.read<LocationProvider>().currentLocation;
  print('Ubicación: ${location?.latitude}, ${location?.longitude}');
}
```

### Obtener dirección desde coordenadas

```dart
final address = await context.read<LocationProvider>()
  .getAddressFromCurrentLocation();
print('Dirección: $address');
```

---

## 2. Geocodificación (GeocodingService)

### Convertir dirección a coordenadas

```dart
import 'lib/services/geocoding_service.dart';

final location = await GeocodingService.geocodeAddress(
  'Calle 10 123, Medellín, Colombia'
);

if (location != null) {
  print('Coordenadas: ${location.latitude}, ${location.longitude}');
}
```

### Convertir coordenadas a dirección

```dart
final address = await GeocodingService.reverseGeocode(
  latitude: 6.2442,
  longitude: -75.5812,
);
print('Dirección: $address');
```

### Buscar direcciones similares

```dart
final addresses = await GeocodingService.searchAddresses('Carrera 5');
for (var addr in addresses) {
  print(addr);
}
```

### Validar si una dirección existe

```dart
final isValid = await GeocodingService.validateAddress('Calle 10 123, Medellín');
print('Válida: $isValid');
```

---

## 3. Rutas Optimizadas (MapsService & MapsProvider)

### IMPORTANTE: Configurar API Key

Primero, obtén tu API Key de Google:
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto
3. Habilita "Directions API" y "Geocoding API"
4. Crea una credencial (API Key)
5. Actualiza en `lib/constants/app_constants.dart`:

```dart
static const String googleMapsApiKey = 'AIzaSyD...tu_api_key...';
```

### Ruta simple entre dos puntos

```dart
import 'lib/providers/maps_provider.dart';
import 'lib/services/maps_service.dart';

final mapsProvider = context.read<MapsProvider>();

final success = await mapsProvider.getRoute(
  origin: LatLng(latitude: 6.2442, longitude: -75.5812),
  destination: LatLng(latitude: 6.2500, longitude: -75.5900),
);

if (success && mapsProvider.currentRoute != null) {
  print('Distancia: ${mapsProvider.currentRoute!.distanceKm} km');
  print('Tiempo: ${mapsProvider.currentRoute!.durationFormatted}');
  print('Polyline: ${mapsProvider.currentRoute!.polylineEncoded}');
}
```

### Ruta optimizada con múltiples paradas

```dart
// Calcular ruta que pase por 3 recogidas optimizando el orden
final waypoints = [
  LatLng(latitude: 6.250, longitude: -75.590),  // Recogida 1
  LatLng(latitude: 6.260, longitude: -75.580),  // Recogida 2
  LatLng(latitude: 6.270, longitude: -75.600),  // Recogida 3
];

final success = await mapsProvider.getOptimizedRoute(
  origin: LatLng(latitude: 6.2442, longitude: -75.5812),  // Ubicación actual
  destination: LatLng(latitude: 6.280, longitude: -75.570),  // Oficina
  waypoints: waypoints,
);

if (success) {
  final route = mapsProvider.optimizedRoute;
  print('Distancia total: ${route?.distanceKm} km');
  print('Tiempo total: ${route?.durationFormatted}');
  
  // Usa route?.points para dibujar polyline en el mapa
  // Usa route?.polylineEncoded para almacenar
}
```

### Estimar tiempo y distancia rápidamente

```dart
final estimate = await mapsProvider.getTravelEstimate(
  origin: LatLng(latitude: 6.2442, longitude: -75.5812),
  destination: LatLng(latitude: 6.2500, longitude: -75.5900),
);

if (estimate != null) {
  print('Distancia: ${estimate['distancia']}');
  print('Duración: ${estimate['duracion']}');
  print('Minutos: ${estimate['tiempo_minutos']}');
}
```

### Calcular distancia entre dos puntos

```dart
final distanceMeters = mapsProvider.calculateDistance(
  point1: LatLng(latitude: 6.2442, longitude: -75.5812),
  point2: LatLng(latitude: 6.2500, longitude: -75.5900),
);
print('Distancia: $distanceMeters metros');
```

---

## 4. Notificaciones Push (FirebaseService)

### IMPORTANTE: Configurar Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea proyecto "loginova"
3. Agrega app Flutter (Android + iOS)
4. Descarga `google-services.json` (Android) → `android/app/`
5. Descarga `GoogleService-Info.plist` (iOS) → `ios/Runner/`
6. Actualiza `lib/constants/app_constants.dart`:

```dart
static const String firebaseProjectId = 'loginova-proyecto';
```

### Escuchar notificaciones en tu app

```dart
import 'lib/services/firebase_service.dart';

@override
void initState() {
  super.initState();
  
  // Notificaciones cuando la app está visible
  FirebaseService.onNotificationReceived((data) {
    print('Notificación: ${data.title}');
    print('Cuerpo: ${data.body}');
    print('Tipo: ${data.type}');
    
    // Navega según tipo
    if (data.type == NotificationType.recogidaAsignada) {
      // Ir a detalle de recogida
      Navigator.pushNamed(context, '/detalle-recogida');
    }
  });
  
  // Cuando usuario toca la notificación
  FirebaseService.onNotificationTapped((data) {
    print('Usuario tocó: ${data.title}');
    // Navega al lugar correspondiente
  });
}
```

### Registrar token FCM (backend recibe ubicaciones)

```dart
// Esto se hace automáticamente cuando:
// 1. El usuario inicia sesión
// 2. El token cambia

// Para obtener token manual:
final token = await FirebaseService.getFCMToken();
print('Token FCM: $token');
```

### Enviar notificación de prueba

```dart
// En el backend, envía POST a:
// POST /api/notificaciones/test
// Headers: Authorization: Bearer {token}

// O en Flutter, usa:
final success = await FirebaseService.sendTestNotification();
print(success ? 'Notificación enviada' : 'Error');
```

---

## 5. Widgets Útiles

### Mostrar información de ruta

```dart
import 'lib/widgets/route_widgets.dart';

RouteInfoCard(
  route: context.watch<MapsProvider>().currentRoute,
  onClose: () => context.read<MapsProvider>().clearRoute(),
)
```

### Botón para calcular ruta

```dart
RouteCalculatorButton(
  label: 'Calcular Ruta',
  isLoading: context.watch<MapsProvider>().isLoadingRoute,
  onPressed: () async {
    // Tu lógica aquí
  },
)
```

### Widget de rastreo de ubicación

```dart
LocationTrackingWidget()
```

---

## 6. Ejemplo Completo: MapaScreen Mejorado

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lib/providers/location_provider.dart';
import 'lib/providers/maps_provider.dart';
import 'lib/services/maps_service.dart';
import 'lib/widgets/route_widgets.dart';

class MapaScreenMejorado extends StatefulWidget {
  @override
  State<MapaScreenMejorado> createState() => _MapaScreenMejoradoState();
}

class _MapaScreenMejoradoState extends State<MapaScreenMejorado> {
  GoogleMapController? mapController;
  final Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Obtener ubicación actual
    await context.read<LocationProvider>().getCurrentLocation();
    
    // Iniciar rastreo
    await context.read<LocationProvider>().startTracking();
  }

  Future<void> _calculateRoute() async {
    final locationProvider = context.read<LocationProvider>();
    final mapsProvider = context.read<MapsProvider>();
    
    final currentLoc = locationProvider.currentLocation;
    if (currentLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación no disponible')),
      );
      return;
    }

    // Destino de ejemplo
    final destination = LatLng(latitude: 6.2500, longitude: -75.5900);

    // Calcular ruta
    final success = await mapsProvider.getRoute(
      origin: LatLng(
        latitude: currentLoc.latitude,
        longitude: currentLoc.longitude,
      ),
      destination: destination,
    );

    if (success && mapsProvider.currentRoute != null) {
      // Agregar polyline al mapa
      _updatePolylines();
    }
  }

  void _updatePolylines() {
    final route = context.read<MapsProvider>().currentRoute;
    if (route == null) return;

    polylines.clear();
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: route.points
            .map((p) => LatLng(latitude: p.latitude, longitude: p.longitude))
            .toList(),
        color: Colors.blue,
        width: 5,
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    context.read<LocationProvider>().stopTracking();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa con Rutas')),
      body: Stack(
        children: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final location = locationProvider.currentLocation;
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location != null
                      ? LatLng(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        )
                      : const LatLng(6.2442, -75.5812),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  mapController = controller;
                },
                polylines: polylines,
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                RouteCalculatorButton(
                  isLoading: context.watch<MapsProvider>().isLoadingRoute,
                  onPressed: _calculateRoute,
                ),
                const SizedBox(height: 12),
                RouteInfoCard(
                  route: context.watch<MapsProvider>().currentRoute,
                  onClose: () => context.read<MapsProvider>().clearRoute(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. Checklist de Configuración

- [ ] Google Maps API Key configurada en `app_constants.dart`
- [ ] Firebase configurado (google-services.json + GoogleService-Info.plist)
- [ ] Permisos Android agregados (AndroidManifest.xml)
- [ ] Permisos iOS agregados (Info.plist)
- [ ] Dependencias instaladas: `flutter pub get`
- [ ] Backend migración ejecutada: `dotnet ef database update`
- [ ] Backend corriendo en puerto 5105

---

## 8. Solución de Problemas

### "API Key no configurada"
```dart
MapsService.setApiKey(AppConstants.googleMapsApiKey);
```

### "Permiso de ubicación denegado"
```dart
// iOS: Agregaste NSLocationWhenInUseUsageDescription en Info.plist?
// Android: Agregaste permisos en AndroidManifest.xml?
```

### "Firebase no inicializa"
```dart
// Descargaste google-services.json y GoogleService-Info.plist?
// Los copiaste en los lugares correctos?
```

### "Notificaciones no llegan"
```dart
// 1. ¿El backend tiene NotificacionService registrado?
// 2. ¿El dispositivo tiene FCM token?
// 3. ¿El usuario está autenticado?
```

---

¡Disfruta con las nuevas funcionalidades! 🚀
