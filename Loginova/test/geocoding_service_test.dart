import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/services/geocoding_service.dart';

void main() {
  group('GeocodingService', () {
    test('formats a Nominatim result into a readable address', () {
      final result = {
        'display_name': 'Calle 100 # 45-67, Medellín, Antioquia, Colombia',
      };

      expect(
        GeocodingService.formatNominatimAddress(result),
        'Calle 100 # 45-67, Medellín, Antioquia, Colombia',
      );
    });

    test('builds search URIs with localized parameters', () {
      final uri = GeocodingService.buildSearchUri('Cra 45 # 20-30', limit: 4);

      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.path, '/search');
      expect(uri.queryParameters['format'], 'jsonv2');
      expect(uri.queryParameters['limit'], '4');
      expect(uri.queryParameters['q'], 'Cra 45 # 20-30');
      expect(uri.queryParameters['addressdetails'], '1');
      expect(uri.queryParameters['accept-language'], 'es');
    });

    test('builds reverse geocoding URIs with coordinates', () {
      final uri = GeocodingService.buildReverseGeocodeUri(6.2442, -75.5812);

      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.path, '/reverse');
      expect(uri.queryParameters['format'], 'jsonv2');
      expect(uri.queryParameters['lat'], '6.2442');
      expect(uri.queryParameters['lon'], '-75.5812');
      expect(uri.queryParameters['accept-language'], 'es');
    });

    test('builds a location payload from a Nominatim result', () {
      final result = {'lat': '6.2442', 'lon': '-75.5812'};

      final location = GeocodingService.parseNominatimLocation(result);

      expect(location, isNotNull);
      expect(location!.latitude, closeTo(6.2442, 0.0001));
      expect(location.longitude, closeTo(-75.5812, 0.0001));
    });
  });
}
