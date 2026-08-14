import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loginova/services/auth_service.dart';

void main() {
  group('AuthService.login', () {
    test('credenciales invalidas propaga el mensaje real del backend', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        return http.Response(
          jsonEncode({'mensaje': 'Credenciales invalidas'}),
          401,
        );
      });

      await http.runWithClient(() async {
        await expectLater(
          AuthService().login('correo@test.com', 'malapass'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.mensaje,
              'mensaje',
              'Credenciales invalidas',
            ),
          ),
        );
      }, () => client);
    });

    test('cuenta desactivada propaga el mensaje especifico del backend', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'mensaje':
                'Esta cuenta está desactivada. Contacta a tu administrador o a soporte.',
          }),
          401,
        );
      });

      await http.runWithClient(() async {
        await expectLater(
          AuthService().login('correo@test.com', 'pass123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('desactivada'),
            ),
          ),
        );
      }, () => client);
    });

    test('respuesta de error sin cuerpo JSON usa el mensaje generico', () async {
      final client = MockClient((request) async {
        return http.Response('', 500);
      });

      await http.runWithClient(() async {
        await expectLater(
          AuthService().login('correo@test.com', 'pass123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.mensaje,
              'mensaje',
              'Correo o contraseña incorrectos',
            ),
          ),
        );
      }, () => client);
    });
  });

  group('AuthService.forgotPassword', () {
    test('devuelve true cuando el backend responde 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/forgot-password');
        return http.Response(jsonEncode({'mensaje': 'ok'}), 200);
      });

      await http.runWithClient(() async {
        final resultado = await AuthService().forgotPassword('correo@test.com');
        expect(resultado, isTrue);
      }, () => client);
    });

    test('devuelve false cuando el backend responde un error', () async {
      final client = MockClient((request) async {
        return http.Response('', 429);
      });

      await http.runWithClient(() async {
        final resultado = await AuthService().forgotPassword('correo@test.com');
        expect(resultado, isFalse);
      }, () => client);
    });
  });

  group('AuthService.resetPassword', () {
    test('devuelve true cuando el backend responde 204', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/reset-password');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['correo'], 'correo@test.com');
        expect(body['token'], '123456');
        expect(body['nuevaPassword'], 'NuevaPass1');
        return http.Response('', 204);
      });

      await http.runWithClient(() async {
        final resultado = await AuthService().resetPassword(
          'correo@test.com',
          '123456',
          'NuevaPass1',
        );
        expect(resultado, isTrue);
      }, () => client);
    });

    test('devuelve false cuando el codigo es invalido o expiro', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'Código inválido o expirado'}), 400);
      });

      await http.runWithClient(() async {
        final resultado = await AuthService().resetPassword(
          'correo@test.com',
          '000000',
          'NuevaPass1',
        );
        expect(resultado, isFalse);
      }, () => client);
    });
  });
}
