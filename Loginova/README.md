# Loginova (Frontend Flutter)

## ¿Qué es?
Aplicación móvil Flutter para la logística y recolección de envíos.

## Estructura principal
- `lib/` → código Dart y UI
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` → plataformas soportadas
- `pubspec.yaml` → dependencias y configuración de Flutter

## Comandos principales
```powershell
cd "c:\Users\ozuna\new proyect\Loginova"
flutter pub get
flutter run
```

## Compilar
- Android:
```powershell
flutter build apk
```
- iOS:
```powershell
flutter build ios
```

## Conectar con el backend
Asegúrate de que la URL del backend sea correcta en tu archivo de configuración o constantes.
Por ejemplo, si el backend corre en `localhost:5000`:
```dart
const String API_BASE_URL = 'http://localhost:5000';
```

## Buenas prácticas para el frontend
- No mezcles archivos de Flutter con archivos de .NET
- Usa `flutter pub get` siempre después de cambiar dependencias
- Usa `flutter clean` si hay errores extraños de compilación
- Mantén los componentes y proveedores bien separados en `lib/`
