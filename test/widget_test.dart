import 'package:flutter_test/flutter_test.dart';

import 'package:inimigos_da_bola/main.dart';

void main() {
  testWidgets('mostra a home do racha', (tester) async {
    await tester.pumpWidget(const InimigosDaBolaApp());

    expect(find.text('Inimigos da Bola'), findsOneWidget);
    expect(find.text('Racha de segunda — 03/06'), findsOneWidget);
    expect(find.text('12 de 20 confirmados'), findsOneWidget);
    expect(find.text('Meu skill'), findsOneWidget);
    expect(find.text('Vou!'), findsOneWidget);
    expect(find.text('Não vou'), findsOneWidget);
  });
}
