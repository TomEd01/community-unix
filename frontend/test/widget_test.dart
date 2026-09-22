import 'package:comunidad_unix_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla de inicio de sesión', (tester) async {
    await tester.pumpWidget(const ComunidadUnixApp());

    expect(find.text('Bienvenido a Comunidad Unix ITC'), findsOneWidget);
    expect(find.text('Iniciar sesión con Google'), findsOneWidget);
  });
}
