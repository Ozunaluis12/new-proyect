import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loginova/main.dart';

void main() {
  testWidgets('muestra formulario de inicio de sesion', (tester) async {
    await tester.pumpWidget(const LoginovaApp());
    await tester.pump(const Duration(seconds: 1));

    // El título "LOGINOVA" se anima letra por letra (AnimatedTitle), así que
    // no existe un único Text('LOGINOVA'); se valida reconstruyendo el texto
    // a partir de las letras individuales en pantalla.
    final letters = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .join();
    expect(letters, contains('LOGINOVA'));

    expect(find.text('Gestión Logística Profesional'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
