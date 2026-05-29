import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../db/database_providers.dart';
import 'sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    syncDao: ref.watch(syncDaoProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
  );
});
