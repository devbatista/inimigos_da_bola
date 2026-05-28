import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/auth/auth_providers.dart';
import 'package:inimigos_da_bola/core/auth/auth_repository.dart';
import 'package:inimigos_da_bola/core/auth/auth_tokens.dart';
import 'package:inimigos_da_bola/main.dart';

void main() {
  testWidgets('mostra login quando não há sessão salva', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const InimigosDaBolaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('login local temporário libera a home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const InimigosDaBolaApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText).at(0),
      AuthRepository.devEmail,
    );
    await tester.enterText(
      find.byType(EditableText).at(1),
      AuthRepository.devPassword,
    );
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.text('Racha de segunda — 03/06'), findsOneWidget);
  });

  testWidgets('mostra a home do racha quando há sessão salva', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            InMemoryTokenStorage(
              const AuthTokens(
                accessToken: 'access-token',
                refreshToken: 'refresh-token',
              ),
            ),
          ),
        ],
        child: const InimigosDaBolaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inimigos da Bola'), findsOneWidget);
    expect(find.text('Racha de segunda — 03/06'), findsOneWidget);
    expect(find.text('12 de 20 confirmados'), findsOneWidget);
    expect(find.text('Meu skill'), findsOneWidget);
    expect(find.text('Vou!'), findsOneWidget);
    expect(find.text('Não vou'), findsOneWidget);
  });
}
