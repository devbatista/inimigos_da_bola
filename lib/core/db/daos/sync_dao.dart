import 'package:drift/drift.dart';

import '../app_database.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueue, SyncState])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Stream<List<SyncQueueData>> watchPendingMutations() {
    return (select(
      syncQueue,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).watch();
  }

  Stream<List<SyncStateData>> watchSyncStates() {
    return select(syncState).watch();
  }

  Future<List<SyncQueueData>> listPendingMutations({int maxAttempts = 10}) {
    return (select(syncQueue)
          ..where((row) => row.attempts.isSmallerThanValue(maxAttempts))
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<void> enqueueMutation(SyncQueueCompanion mutation) {
    return into(syncQueue).insert(mutation);
  }

  Future<void> markMutationFailed({
    required String id,
    required int attempts,
    required String error,
  }) {
    return (update(syncQueue)..where((row) => row.id.equals(id))).write(
      SyncQueueCompanion(attempts: Value(attempts), lastError: Value(error)),
    );
  }

  Future<void> deleteMutation(String id) {
    return (delete(syncQueue)..where((row) => row.id.equals(id))).go();
  }

  Future<void> upsertSyncState(SyncStateCompanion state) {
    return into(syncState).insertOnConflictUpdate(state);
  }
}
