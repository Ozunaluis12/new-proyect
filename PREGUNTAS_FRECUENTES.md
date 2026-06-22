# ❓ PREGUNTAS FRECUENTES - Nuevas Funcionalidades

## 🤔 ¿Por dónde empiezo?

### Respuesta rápida
1. Lee `INICIO_RAPIDO.md` (5 min)
2. Ejecuta `flutter pub get` (2 min)
3. Configura Google Maps API Key (10 min)
4. Configura Firebase (15 min)
5. Ejecuta `flutter run` (5 min)

**Total: ~40 minutos**

---

## 📍 Preguntas sobre Posición Real-time

### P: ¿Cómo inicio el rastreo de ubicación?
```dart
await context.read<LocationProvider>().startTracking();
```

### P: ¿Con qué frecuencia se actualiza?
Cada 30 segundos (configurable en LocationService._updateIntervalSeconds)

### P: ¿Se sigue rastreando si cierro la app?
No, solo rastrea mientras la app está ejecutándose en foreground o background.
Para background continuo, implementar ServicesBinding.

### P: ¿Funciona en iOS y Android?
Sí, ambas plataformas están configuradas.

### P: ¿Qué permisos necesito?
- Android: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- iOS: NSLocationWhenInUseUsageDescription

---

## 🗺️ Preguntas sobre Geocodificación

### P: ¿Qué es geocodificación?
Convertir una dirección de texto en coordenadas (y viceversa).

### P: ¿Cuál es la diferencia entre geocoding y reverse geocoding?
- **Geocoding**: "Calle 10 123" → (6.2442, -75.5812)
- **Reverse Geocoding**: (6.2442, -75.5812) → "Calle 10 123"

### P: ¿Funciona sin internet?
No, necesita conexión para consultar los servidores de Google.

### P: ¿Puedo usar otro proveedor?
Sí, modifica GeocodingService para usar Google, OpenStreetMap, etc.

### P: ¿Es gratis?
Google proporciona cuota gratuita mensual. Ver [Google Geocoding Pricing](https://developers.google.com/maps/billing-and-pricing/pricing).

---

## 🛣️ Preguntas sobre Rutas Optimizadas

### P: ¿Cuál es la diferencia entre getRoute() y getOptimizedRoute()?
- **getRoute()**: Calcula ruta entre 2 puntos (A → B)
- **getOptimizedRoute()**: Calcula ruta visitando múltiples paradas (A → W1 → W2 → W3 → B) con orden optimizado

### P: ¿Cómo uso getOptimizedRoute()?
```dart
final route = await MapsService.getOptimizedRoute(
  origin: LatLng(latitude: 6.2442, longitude: -75.5812),
  destination: LatLng(latitude: 6.2500, longitude: -75.5900),
  waypoints: [recogida1, recogida2, recogida3],
  optimizeWaypoints: true, // Calcula orden óptimo
);
```

### P: ¿Cuántas paradas puedo agregar?
Google permite hasta 25 waypoints (más algunos límites de ruta).
En práctica: 8-10 funciona bien.

### P: ¿Cómo dibujo la ruta en el mapa?
```dart
final route = mapsProvider.currentRoute;
final polylines = {
  Polyline(
    polylineId: PolylineId('route'),
    points: route.points.map((p) => LatLng(...)).toList(),
    color: Colors.blue,
  ),
};
```

### P: ¿Necesito API Key?
Sí, Google Maps API Key con Directions API habilitada.

### P: ¿Es gratis?
Google proporciona cuota gratuita. Ver [Google Maps Pricing](https://developers.google.com/maps/billing-and-pricing).

---

## 🔔 Preguntas sobre Notificaciones Push

### P: ¿Necesito Firebase?
Sí, para recibir notificaciones push en dispositivos.

### P: ¿Cómo registro el token FCM?
Automáticamente cuando inicializas FirebaseService en main():
```dart
await FirebaseService.initialize();
```

### P: ¿Cómo recibo una notificación?
```dart
FirebaseService.onNotificationReceived((data) {
  print('Recibida: ${data.title}');
});
```

### P: ¿Cómo envío una notificación desde el backend?
```csharp
var request = new NotificacionRequest(
  usuarioId: 5,
  titulo: "Recogida asignada",
  cuerpo: "Se asignó una nueva recogida",
  tipo: "recogida_asignada"
);
await _notificacionService.EnviarNotificacion(request);
```

### P: ¿Funciona en background?
Sí, Firebase Cloud Messaging maneja automáticamente notificaciones en background.

### P: ¿Cómo pruebo en desarrollo?
```csharp
POST /api/notificaciones/test
Authorization: Bearer {token}
```

---

## ⚙️ Configuración

### P: ¿Dónde configuro la API Key?
```dart
// lib/constants/app_constants.dart
static const String googleMapsApiKey = 'AIzaSyD...';
```

### P: ¿Dónde configuro Firebase Project ID?
```dart
// lib/constants/app_constants.dart
static const String firebaseProjectId = 'loginova-proyecto';
```

### P: ¿Necesito reiniciar la app después de cambiar keys?
Sí, ejecuta `flutter run` nuevamente.

### P: ¿Cómo obtengo una Google Maps API Key?
1. Ir a https://console.cloud.google.com/
2. Crear proyecto
3. APIs & Services → Enable Directions API
4. Credenciales → Crear API Key
5. Copiar en app_constants.dart

### P: ¿Cómo configuro Firebase?
1. Ir a https://console.firebase.google.com/
2. Crear proyecto "loginova"
3. Agregar app Flutter
4. Descargar configuraciones
5. Copiar en carpetas correctas

---

## 🚀 Deployment

### P: ¿Puedo subir a producción ahora?
No, primero:
- [ ] Configurar Google Maps API Key
- [ ] Configurar Firebase
- [ ] Testing en dispositivo real
- [ ] Code review

### P: ¿Qué pasa si no configuro los keys?
La app compilará pero las funcionalidades de mapas y notificaciones no funcionarán.

### P: ¿Cómo protejo mis API Keys?
Para producción:
- No incluyas keys en el código
- Usa variables de entorno
- Implementa backend proxy para llamadas a APIs

---

## 🐛 Troubleshooting

### P: "API Key no configurada"
```
Solución:
1. Abre lib/constants/app_constants.dart
2. Reemplaza 'TU_API_KEY_AQUI' con tu key
3. Ejecuta flutter run nuevamente
```

### P: "Permiso de ubicación denegado"
```
Android:
1. Abre android/app/src/main/AndroidManifest.xml
2. Verifica que tengas los permisos agregados
3. Reinstala la app

iOS:
1. Abre ios/Runner/Info.plist
2. Verifica NSLocationWhenInUseUsageDescription
3. Reinstala la app
```

### P: "Firebase error: Failed to initialize"
```
Solución:
1. Descarga google-services.json (Android)
2. Descarga GoogleService-Info.plist (iOS)
3. Cópialos en las carpetas correctas
4. flutter clean
5. flutter run
```

### P: "Notificaciones no llegan"
```
Verificar:
1. ¿Backend tiene NotificacionService registrado?
2. ¿Dispositivo tiene FCM token?
3. ¿Usuario está autenticado?
4. ¿Firebase configurado?
5. Ver logs: adb logcat | grep firebase
```

### P: "Ruta no se calcula"
```
Verificar:
1. ¿Google Maps API Key configurada?
2. ¿Directions API habilitada en Google Cloud?
3. ¿Coordenadas válidas?
4. ¿Internet disponible?
```

---

## 📊 Performance

### P: ¿Cuánto consume la batería el rastreo?
Depende:
- Cada 30 segundos: ~15-25% extra
- Puedes aumentar interval en LocationService
- Detén rastreo cuando no sea necesario

### P: ¿Cuánto datos consume?
Ubicación: ~1 KB cada 30 segundos = ~2.88 MB/mes
Rutas: Depende de complejidad de ruta

### P: ¿Qué tan rápido calcula rutas?
Google Maps API: 1-3 segundos típicamente

---

## 💾 Almacenamiento

### P: ¿Dónde se guardan las ubicaciones?
Backend en PostgreSQL tabla `ubicaciones`

### P: ¿Cuánto espacio ocupa?
Cada ubicación: ~200 bytes
10,000 ubicaciones: ~2 MB

### P: ¿Debo limpiar datos antiguos?
Recomendación: Implementar política de retención
```sql
DELETE FROM ubicaciones WHERE fecha_registro < NOW() - INTERVAL 90 days;
```

---

## 🔒 Seguridad

### P: ¿Son seguros los tokens FCM?
Sí, Firebase maneja tokens de forma segura.

### P: ¿Quién puede enviar notificaciones?
Solo usuarios con rol Administrador y endpoints protegidos.

### P: ¿Se encriptan las ubicaciones?
En tránsito: Sí (HTTPS/TLS)
En reposo: No (considera implementar)

---

## 📈 Escalabilidad

### P: ¿Funciona con 10,000 usuarios?
Sí, pero requiere:
- Índices en BD
- Caché en Redis
- Load balancing

### P: ¿Qué pasa con 1 millón de eventos?
Considerar:
- Particionamiento de tablas
- Archivado de datos antiguos
- Elasticsearch para búsqueda

---

## 📚 Documentación

### P: ¿Dónde está el código de ejemplo?
```
Ver: GUIA_USO_NUEVAS_FUNCIONALIDADES.md
     - Posición real-time
     - Geocodificación
     - Rutas optimizadas
     - Notificaciones push
```

### P: ¿Cuáles son los próximos pasos?
```
Ver: INICIO_RAPIDO.md
     - Setup en 5 minutos
     - Configuración de APIs
     - Inicio de testing
```

---

## 💬 ¿No encontraste tu pregunta?

Revisa:
1. `GUIA_USO_NUEVAS_FUNCIONALIDADES.md` - Ejemplos código
2. `INICIO_RAPIDO.md` - Setup rápido
3. `RESUMEN_IMPLEMENTACION_FINAL.md` - Cambios realizados
4. `ESTADO_PROYECTO.md` - Visión general
5. `CHECKLIST_IMPLEMENTACION.md` - Progreso

---

**Última actualización: 22 de Junio, 2026**
