import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../api/api_exception.dart';
import '../api/clients/sync_api_client.dart';
import '../db/app_database.dart';
import '../db/daos/sync_dao.dart';

typedef SyncPush =
    Future<Map<String, dynamic>> Function({
      required String entity,
      required String mutationId,
      required String operation,
      required Map<String, dynamic> record,
    });

class SyncEngine {
  SyncEngine({
    required SyncDao syncDao,
    required SyncApiClient syncApiClient,
    SyncPush? push,
    Duration Function(int attempts)? backoffForAttempts,
  }) : _syncDao = syncDao,
       _push = push ?? syncApiClient.push,
       _backoffForAttempts = backoffForAttempts ?? _defaultBackoff;

  static const maxAttempts = 10;

  final SyncDao _syncDao;
  final SyncPush _push;
  final Duration Function(int attempts) _backoffForAttempts;

  bool _draining = false;

  Future<void> drain() async {
    if (_draining) {
      return;
    }

    _draining = true;
    try {
      final mutations = await _syncDao.listPendingMutations(
        maxAttempts: maxAttempts,
      );
      for (final mutation in mutations) {
        await _drainMutation(mutation);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainMutation(SyncQueueData mutation) async {
    if (mutation.attempts > 0) {
      await Future<void>.delayed(_backoffForAttempts(mutation.attempts));
    }

    try {
      final record = _decodeRecord(mutation.payloadJson);
      await _push(
        entity: mutation.entity,
        mutationId: mutation.mutationId,
        operation: mutation.operation,
        record: record,
      );
      await _syncDao.deleteMutation(mutation.id);
    } catch (error) {
      final attempts = mutation.attempts + 1;
      final message = attempts >= maxAttempts
          ? 'Suspensa após $maxAttempts tentativas: ${_errorMessage(error)}'
          : _errorMessage(error);
      await _syncDao.markMutationFailed(
        id: mutation.id,
        attempts: attempts,
        error: message,
      );
    }
  }

  Map<String, dynamic> _decodeRecord(String payloadJson) {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Payload de sync inválido.');
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Não foi possível sincronizar.';
  }

  static Duration _defaultBackoff(int attempts) {
    final seconds = min(300, pow(2, attempts).toInt());
    return Duration(seconds: seconds);
  }
}
