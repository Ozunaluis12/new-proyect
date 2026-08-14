import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ApiService.setServerUrlOverride/loadServerUrlOverride pasan por
  // FlutterSecureStorage, que en `flutter test` no tiene una implementación
  // nativa detrás del MethodChannel. Se simula con un almacén en memoria
  // para poder probar la lógica real del servicio sin tocar el disco.
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final almacen = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async {
    switch (call.method) {
      case 'write':
        almacen[call.arguments['key'] as String] =
            call.arguments['value'] as String;
        return null;
      case 'read':
        return almacen[call.arguments['key'] as String];
      case 'delete':
        almacen.remove(call.arguments['key'] as String);
        return null;
      default:
        return null;
    }
  });

  // baseUrl decide a que backend habla toda la app segun la plataforma; un
  // error aca (ver notas del README sobre 127.0.0.1 vs 10.0.2.2 vs IP de LAN)
  // deja la app entera sin poder conectar.
  group('ApiService.baseUrl', () {
    tearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await ApiService.setServerUrlOverride(null);
    });

    test('en Android usa 10.0.2.2 (el emulador no resuelve localhost al host)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ApiService.baseUrl, 'http://10.0.2.2:5105/api');
    });

    test('en iOS usa 127.0.0.1', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(ApiService.baseUrl, 'http://127.0.0.1:5105/api');
    });
  });

  group('ApiService.setServerUrlOverride', () {
    tearDown(() async {
      await ApiService.setServerUrlOverride(null);
    });

    test('recorta espacios y la barra final antes de guardarla', () async {
      await ApiService.setServerUrlOverride('  http://192.168.1.50:5105/api/  ');
      expect(ApiService.serverUrlOverride, 'http://192.168.1.50:5105/api');
    });

    test('un valor vacio o solo espacios limpia el override', () async {
      await ApiService.setServerUrlOverride('http://192.168.1.50:5105/api');
      await ApiService.setServerUrlOverride('   ');
      expect(ApiService.serverUrlOverride, isNull);
    });

    test('la url configurada manualmente tiene prioridad sobre la de plataforma', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await ApiService.setServerUrlOverride('http://192.168.1.50:5105/api');

      expect(ApiService.baseUrl, 'http://192.168.1.50:5105/api');

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('ApiService.jsonHeaders', () {
    test('sin token no incluye el encabezado Authorization', () {
      ApiService.token = null;
      expect(ApiService.jsonHeaders.containsKey('Authorization'), isFalse);
    });

    test('con token incluye el encabezado Bearer', () {
      ApiService.token = 'un-token-jwt';
      expect(ApiService.jsonHeaders['Authorization'], 'Bearer un-token-jwt');
      ApiService.token = null;
    });
  });
}
