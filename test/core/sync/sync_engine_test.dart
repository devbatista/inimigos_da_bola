import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/api/api_client.dart';
import 'package:inimigos_da_bola/core/api/api_exception.dart';
import 'package:inimigos_da_bola/core/api/clients/sync_api_client.dart';
import 'package:inimigos_da_bola/core/db/app_database.dart';
import 'package:inimigos_da_bola/core/sync/sync_engine.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('envia mutação pendente e remove da fila em sucesso', () async {
    final pushed = <Map<String, dynamic>>[];
    await _enqueueMutation(database, attempts: 0);
    final engine = SyncEngine(
      syncDao: database.syncDao,
      syncApiClient: _UnusedSyncApiClient(),
      backoffForAttempts: (_) => Duration.zero,
      push:
          ({
            required entity,
            required mutationId,
            required operation,
            required record,
          }) async {
            pushed.add({
              'entity': entity,
              'mutation_id': mutationId,
              'operation': operation,
              'record': record,
            });
            return const {};
          },
    );

    await engine.drain();

    final pending = await database.syncDao.listPendingMutations();
    expect(pending, isEmpty);
    expect(pushed.single['entity'], 'session_stats');
    expect(pushed.single['mutation_id'], 'mutation-1');
    expect(pushed.single['record']['goals'], 2);
  });

  test('incrementa tentativas e preserva mutação em falha', () async {
    await _enqueueMutation(database, attempts: 2);
    final engine = SyncEngine(
      syncDao: database.syncDao,
      syncApiClient: _UnusedSyncApiClient(),
      backoffForAttempts: (_) => Duration.zero,
      push:
          ({
            required entity,
            required mutationId,
            required operation,
            required record,
          }) async {
            throw const ApiException(
              code: 'network_error',
              message: 'Sem conexão.',
            );
          },
    );

    await engine.drain();

    final pending = await database.syncDao.watchPendingMutations().first;
    expect(pending.single.attempts, 3);
    expect(pending.single.lastError, 'Sem conexão.');
  });

  test('suspende mutação após dez tentativas', () async {
    await _enqueueMutation(database, attempts: 9);
    final engine = SyncEngine(
      syncDao: database.syncDao,
      syncApiClient: _UnusedSyncApiClient(),
      backoffForAttempts: (_) => Duration.zero,
      push:
          ({
            required entity,
            required mutationId,
            required operation,
            required record,
          }) async {
            throw const ApiException(
              code: 'network_error',
              message: 'Sem conexão.',
            );
          },
    );

    await engine.drain();

    final all = await database.syncDao.watchPendingMutations().first;
    expect(all.single.attempts, SyncEngine.maxAttempts);
    expect(all.single.lastError, contains('Suspensa'));
    expect(await database.syncDao.listPendingMutations(), isEmpty);
  });
}

Future<void> _enqueueMutation(AppDatabase database, {required int attempts}) {
  return database.syncDao.enqueueMutation(
    SyncQueueCompanion.insert(
      id: 'queue-1',
      entity: 'session_stats',
      entityId: 'stat-1',
      operation: 'create',
      mutationId: 'mutation-1',
      payloadJson: jsonEncode({
        'id': 'stat-1',
        'weekly_session_id': 'session-1',
        'user_id': 'user-1',
        'goals': 2,
        'assists': 1,
        'version': 1,
      }),
      createdAt: DateTime.utc(2026, 5, 29, 12),
      attempts: Value(attempts),
    ),
  );
}

class _UnusedSyncApiClient extends SyncApiClient {
  _UnusedSyncApiClient() : super(ApiClient().dio);
}
