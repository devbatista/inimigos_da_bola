import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/api/clients/sync_api_client.dart';
import '../../../core/api/clients/users_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/users_dao.dart';

class PlayersRepository {
  const PlayersRepository({
    required UsersApiClient usersApiClient,
    required SyncApiClient syncApiClient,
    required UsersDao usersDao,
  }) : _usersApiClient = usersApiClient,
       _syncApiClient = syncApiClient,
       _usersDao = usersDao;

  final UsersApiClient _usersApiClient;
  final SyncApiClient _syncApiClient;
  final UsersDao _usersDao;

  Future<List<User>> load() async {
    final syncJson = await _syncApiClient.pull(entities: const ['users']);
    final entities = syncJson['entities'];
    if (entities is Map<String, dynamic>) {
      for (final user in _entityList(entities, 'users')) {
        await _upsertUser(user);
      }
    }

    return _usersDao.listActiveUsers();
  }

  Future<List<User>> invite({
    required String email,
    required String name,
  }) async {
    final userJson = await _usersApiClient.invite(email: email, name: name);
    if (userJson['id'] != null) {
      await _upsertUser(userJson);
    }

    return load();
  }

  Future<List<User>> update(User user, PlayerUpdate update) async {
    final record = {
      'id': user.id,
      'version': user.version,
      'name': update.name,
      'phone': update.phone,
      'player_type': update.playerType,
      'goalkeeper': update.goalkeeper,
    };

    final response = await _syncApiClient.push(
      entity: 'users',
      mutationId: _uuidV4(),
      operation: 'update',
      record: record,
    );
    final responseRecord = response['record'];
    if (responseRecord is Map<String, dynamic>) {
      await _upsertUser(responseRecord);
    } else {
      await _upsertUser({
        ...record,
        'email': user.email,
        'admin': user.admin,
        'skill_score': user.skillScore,
        'created_at': user.createdAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'version': user.version + 1,
      });
    }

    return _usersDao.listActiveUsers();
  }

  Future<List<User>> softDelete(User user) async {
    await _syncApiClient.push(
      entity: 'users',
      mutationId: _uuidV4(),
      operation: 'delete',
      record: {'id': user.id, 'version': user.version},
    );

    await _usersDao.softDeleteUser(user.id, DateTime.now());
    return _usersDao.listActiveUsers();
  }

  List<Map<String, dynamic>> _entityList(
    Map<String, dynamic> entities,
    String name,
  ) {
    final records = entities[name];
    if (records is! List) {
      return const [];
    }

    return records.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _upsertUser(Map<String, dynamic> json) {
    final now = DateTime.now();

    return _usersDao.upsertUser(
      UsersCompanion.insert(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        createdAt: _date(json['created_at']) ?? now,
        updatedAt: _date(json['updated_at']) ?? now,
        phone: Value(json['phone'] as String?),
        admin: Value(json['admin'] as bool? ?? false),
        playerType: Value(json['player_type'] as String? ?? 'casual'),
        skillScore: Value(_double(json['skill_score'])),
        goalkeeper: Value(json['goalkeeper'] as bool? ?? false),
        deletedAt: Value(_date(json['deleted_at'])),
        version: Value(json['version'] as int? ?? 1),
      ),
    );
  }

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.parse(value).toLocal();
  }

  double? _double(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class PlayerUpdate {
  const PlayerUpdate({
    required this.name,
    required this.phone,
    required this.playerType,
    required this.goalkeeper,
  });

  final String name;
  final String? phone;
  final String playerType;
  final bool goalkeeper;
}
