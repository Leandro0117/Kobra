import 'package:flutter_test/flutter_test.dart';

import 'package:kobra_app/main.dart';

void main() {
  testWidgets('Muestra la pantalla de login cuando no hay sesión guardada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KobraApp());

    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Kobra'), findsWidgets);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
