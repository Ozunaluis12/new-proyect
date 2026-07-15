import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/main.dart';

void main() {
  testWidgets('muestra formulario de inicio de sesion', (tester) async {
    await tester.pumpWidget(const LoginovaApp());

    expect(find.text('LOGINOVA'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
