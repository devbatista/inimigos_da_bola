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

  Future<void> enqueueMutation(SyncQueueCompanion mutation) {
    return into(syncQueue).insert(mutation);
  }

  Future<void> deleteMutation(String id) {
    return (delete(syncQueue)..where((row) => row.id.equals(id))).go();
  }

  Future<void> upsertSyncState(SyncStateCompanion state) {
    return into(syncState).insertOnConflictUpdate(state);
  }
}
