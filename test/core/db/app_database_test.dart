import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/db/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'cria tabelas principais sem campos sensíveis de autenticação',
    () async {
      final columns = await database
          .customSelect('PRAGMA table_info(users)')
          .get();
      final columnNames = columns.map((row) => row.data['name']).toSet();

      expect(columnNames, containsAll(['id', 'email', 'name', 'admin']));
      expect(columnNames, isNot(contains('encrypted_password')));
      expect(columnNames, isNot(contains('password')));
    },
  );

  test('persiste usuário e sessão semanal no cache local', () async {
    final now = DateTime.utc(2026, 5, 27, 20);

    await database.usersDao.upsertUser(
      UsersCompanion.insert(
        id: '01971f8c-1111-7000-8000-000000000001',
        email: 'joao@example.com',
        name: 'João Batista',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.weeklySessionsDao.upsertWeeklySession(
      WeeklySessionsCompanion.insert(
        id: '01971f8c-2222-7000-8000-000000000002',
        scheduledAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final users = await database.usersDao.watchActiveUsers().first;
    final sessions = await database.weeklySessionsDao
        .watchActiveWeeklySessions()
        .first;

    expect(users, hasLength(1));
    expect(users.single.name, 'João Batista');
    expect(sessions, hasLength(1));
    expect(sessions.single.maxPlayers, 20);
  });
}
