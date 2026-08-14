import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/services/geocoding_service.dart';

void main() {
  // Cubre el bug reportado: el buscador de direcciones devolvía resultados
  // de otras ciudades porque la búsqueda a Nominatim no tenía restricción
  // por país ni una caja de sesgo obligatoria. Estas pruebas fijan el
  // contrato de GeocodingService.buildSearchUri para que no se repita.
  //
  // El sesgo por defecto (usado cuando aún no hay GPS) NO está hardcodeado a
  // ninguna ciudad: se configura en tiempo de ejecución con la ciudad de
  // operación de la empresa del usuario logueado (ver
  // GeocodingService.configurarUbicacionPorDefecto, llamado desde
  // AuthProvider al iniciar sesión). Por eso cada test que dependa de ese
  // estado lo deja limpio al terminar, para no filtrarse a los demás.
  tearDown(() {
    GeocodingService.configurarUbicacionPorDefecto(null, null);
  });

  group('GeocodingService.buildSearchUri', () {
    test('siempre restringe la búsqueda a Colombia', () {
      final uri = GeocodingService.buildSearchUri('Calle 10');
      expect(uri.queryParameters['countrycodes'], 'co');
    });

    test('sin ubicación conocida y sin "bounded", no agrega viewbox', () {
      final uri = GeocodingService.buildSearchUri('Calle 10');
      expect(uri.queryParameters.containsKey('viewbox'), isFalse);
      expect(uri.queryParameters.containsKey('bounded'), isFalse);
    });

    test(
      'con "bounded" pero sin ubicación conocida ni ciudad configurada, no hay caja',
      () {
        final uri = GeocodingService.buildSearchUri('Calle 10', bounded: true);

        expect(uri.queryParameters.containsKey('viewbox'), isFalse);
        expect(uri.queryParameters.containsKey('bounded'), isFalse);
      },
    );

    test(
      'con "bounded" y una ciudad de operación configurada, la usa como centro',
      () {
        GeocodingService.configurarUbicacionPorDefecto(7.1193, -73.1227);

        final uri = GeocodingService.buildSearchUri('Calle 10', bounded: true);

        expect(uri.queryParameters['bounded'], '1');
        final viewbox = uri.queryParameters['viewbox'];
        expect(viewbox, isNotNull);

        final partes = viewbox!.split(',').map(double.parse).toList();
        final minLon = partes[0];
        final maxLat = partes[1];
        final maxLon = partes[2];
        final minLat = partes[3];

        expect((minLat + maxLat) / 2, closeTo(7.1193, 0.001));
        expect((minLon + maxLon) / 2, closeTo(-73.1227, 0.001));
      },
    );

    test(
      'con ubicación GPS real, esta tiene prioridad sobre la ciudad configurada',
      () {
        GeocodingService.configurarUbicacionPorDefecto(7.1193, -73.1227);

        final uri = GeocodingService.buildSearchUri(
          'Calle 10',
          nearLatitude: 4.7110,
          nearLongitude: -74.0721,
          bounded: true,
        );

        expect(uri.queryParameters['bounded'], '1');
        final viewbox = uri.queryParameters['viewbox']!.split(',').map(double.parse).toList();
        final minLon = viewbox[0];
        final maxLat = viewbox[1];
        final maxLon = viewbox[2];
        final minLat = viewbox[3];

        expect((minLat + maxLat) / 2, closeTo(4.7110, 0.001));
        expect((minLon + maxLon) / 2, closeTo(-74.0721, 0.001));
      },
    );

    test('sin "bounded", una ubicación conocida sigue aplicando un sesgo suave', () {
      final uri = GeocodingService.buildSearchUri(
        'Calle 10',
        nearLatitude: 4.7110,
        nearLongitude: -74.0721,
      );

      expect(uri.queryParameters.containsKey('viewbox'), isTrue);
      expect(uri.queryParameters.containsKey('bounded'), isFalse);
    });
  });
}
