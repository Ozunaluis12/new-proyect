import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/models/usuario.dart';

void main() {
  group('Usuario.fromJson', () {
    test('parsea todos los campos desde una respuesta tipica del backend', () {
      final usuario = Usuario.fromJson({
        'id': 1,
        'nombre': 'Ana',
        'correo': 'ana@empresa.com',
        'rol': 'Operador',
        'permisos': ['crear_recogidas', 'ver_clientes'],
        'activo': true,
      });

      expect(usuario.id, 1);
      expect(usuario.nombre, 'Ana');
      expect(usuario.correo, 'ana@empresa.com');
      expect(usuario.rol, 'Operador');
      expect(usuario.permisos, ['crear_recogidas', 'ver_clientes']);
      expect(usuario.activo, isTrue);
    });

    test('sesiones guardadas antes del campo activo se tratan como activas', () {
      // Retrocompatibilidad: una sesión guardada en el dispositivo antes de
      // que "activo" existiera en el JSON no debe interpretarse como inactiva.
      final usuario = Usuario.fromJson({
        'id': 1,
        'nombre': 'Ana',
        'correo': 'ana@empresa.com',
        'rol': 'Operador',
        'permisos': [],
      });

      expect(usuario.activo, isTrue);
    });

    test('permisos y rol ausentes no lanzan y usan valores por defecto', () {
      final usuario = Usuario.fromJson({
        'id': 2,
        'nombre': 'Beto',
        'correo': 'beto@empresa.com',
      });

      expect(usuario.rol, '');
      expect(usuario.permisos, isEmpty);
    });
  });

  group('Usuario.toJson', () {
    test('serializa de vuelta un mapa equivalente', () {
      final usuario = Usuario(
        id: 3,
        nombre: 'Carlos',
        correo: 'carlos@empresa.com',
        rol: 'Administrador',
        permisos: const ['gestionar_usuarios'],
        activo: false,
      );

      expect(usuario.toJson(), {
        'id': 3,
        'nombre': 'Carlos',
        'correo': 'carlos@empresa.com',
        'rol': 'Administrador',
        'permisos': ['gestionar_usuarios'],
        'activo': false,
      });
    });
  });

  group('Usuario.tienePermiso', () {
    test('Administrador siempre tiene permiso, incluso sin listarlo explicitamente', () {
      final admin = Usuario(
        id: 1,
        nombre: 'Admin',
        correo: 'admin@empresa.com',
        rol: 'Administrador',
        permisos: const [],
      );

      expect(admin.tienePermiso('gestionar_usuarios'), isTrue);
    });

    test('Administrador en cualquier capitalizacion tambien tiene bypass total', () {
      final admin = Usuario(
        id: 1,
        nombre: 'Admin',
        correo: 'admin@empresa.com',
        rol: 'ADMINISTRADOR',
        permisos: const [],
      );

      expect(admin.tienePermiso('cualquier_permiso'), isTrue);
    });

    test('Operador con el permiso explicito lo tiene', () {
      final operador = Usuario(
        id: 2,
        nombre: 'Op',
        correo: 'op@empresa.com',
        rol: 'Operador',
        permisos: const ['crear_recogidas'],
      );

      expect(operador.tienePermiso('crear_recogidas'), isTrue);
      expect(operador.tienePermiso('CREAR_RECOGIDAS'), isTrue);
    });

    test('Operador sin el permiso no lo tiene', () {
      final operador = Usuario(
        id: 2,
        nombre: 'Op',
        correo: 'op@empresa.com',
        rol: 'Operador',
        permisos: const ['crear_recogidas'],
      );

      expect(operador.tienePermiso('gestionar_usuarios'), isFalse);
    });
  });
}
