import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/api/api_client.dart';
import 'package:inimigos_da_bola/core/api/clients/auth_api_client.dart';
import 'package:inimigos_da_bola/core/auth/auth_providers.dart';
import 'package:inimigos_da_bola/core/auth/auth_repository.dart';
import 'package:inimigos_da_bola/core/auth/auth_tokens.dart';
import 'package:inimigos_da_bola/core/db/app_database.dart';
import 'package:inimigos_da_bola/features/attendance/data/attendance_repository.dart';
import 'package:inimigos_da_bola/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:inimigos_da_bola/features/attendance/presentation/controllers/attendance_providers.dart';
import 'package:inimigos_da_bola/main.dart';

void main() {
  testWidgets('mostra login quando não há sessão salva', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authRepositoryProvider.overrideWith(
            (ref) => _localAuthRepository(InMemoryTokenStorage()),
          ),
          attendanceControllerProvider.overrideWith(
            (ref) => AttendanceController.fake(_homeData()),
          ),
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
    final tokenStorage = InMemoryTokenStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWith(
            (ref) => _localAuthRepository(tokenStorage),
          ),
          attendanceControllerProvider.overrideWith(
            (ref) => AttendanceController.fake(_homeData()),
          ),
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

    expect(find.text('Racha de quarta — 03/06'), findsOneWidget);
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
          attendanceControllerProvider.overrideWith(
            (ref) => AttendanceController.fake(_homeData()),
          ),
        ],
        child: const InimigosDaBolaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Racha de quarta — 03/06'), findsOneWidget);
    expect(find.text('1 de 20 confirmados'), findsOneWidget);
    expect(find.text('Meu skill'), findsOneWidget);
    expect(find.text('Vou!'), findsOneWidget);
    expect(find.text('Não vou'), findsOneWidget);
  });

  testWidgets('mostra menu inferior e ações secundárias em Mais', (
    tester,
  ) async {
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
          attendanceControllerProvider.overrideWith(
            (ref) => AttendanceController.fake(_homeData()),
          ),
        ],
        child: const InimigosDaBolaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Sorteio'), findsOneWidget);
    expect(find.text('Modo Jogo'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Mais'), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmações avulsas'), findsOneWidget);
    expect(find.text('Jogadores'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });
}

AuthRepository _localAuthRepository(InMemoryTokenStorage storage) {
  return AuthRepository(
    authApiClient: AuthApiClient(ApiClient().dio),
    tokenStorage: storage,
  );
}

AttendanceHomeData _homeData() {
  final scheduledAt = DateTime(2026, 6, 3, 20);
  final now = DateTime(2026, 6, 3, 18, 42);
  final currentUser = User(
    id: 'user-1',
    email: 'admin@inimigosdabola.dev',
    name: 'João Batista',
    phone: null,
    admin: true,
    playerType: 'monthly',
    skillScore: 74,
    goalkeeper: true,
    createdAt: scheduledAt,
    updatedAt: scheduledAt,
    deletedAt: null,
    version: 1,
  );

  return AttendanceHomeData(
    session: WeeklySession(
      id: 'session-1',
      scheduledAt: scheduledAt,
      maxPlayers: 20,
      status: 'scheduled',
      createdAt: scheduledAt,
      updatedAt: scheduledAt,
      deletedAt: null,
      version: 1,
    ),
    currentUser: currentUser,
    attendances: [
      Attendance(
        id: 'attendance-1',
        userId: 'user-1',
        weeklySessionId: 'session-1',
        kind: 'registered',
        guestName: null,
        createdByAdminId: null,
        status: 'confirmed',
        waitlistPosition: null,
        createdAt: scheduledAt,
        updatedAt: scheduledAt,
        deletedAt: null,
        version: 1,
      ),
    ],
    usersById: {'user-1': currentUser},
    updatedAt: now,
  );
}
