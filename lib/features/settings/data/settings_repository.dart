import 'package:drift/drift.dart';

import '../../../core/api/clients/users_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/users_dao.dart';

class SettingsRepository {
  const SettingsRepository({
    required UsersApiClient usersApiClient,
    required UsersDao usersDao,
  }) : _usersApiClient = usersApiClient,
       _usersDao = usersDao;

  final UsersApiClient _usersApiClient;
  final UsersDao _usersDao;

  Future<User?> loadProfile() async {
    try {
      final json = await _usersApiClient.me();
      await _upsertUser(json);
      return _userFromJson(json);
    } catch (_) {
      final users = await _usersDao.listActiveUsers();
      return users.isEmpty ? null : users.first;
    }
  }

  Future<User> updateProfile(SettingsProfileUpdate update) async {
    final json = await _usersApiClient.updateMe({
      'name': update.name,
      'phone': update.phone,
      'goalkeeper': update.goalkeeper,
    });
    await _upsertUser(json);
    return _userFromJson(json);
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

  User _userFromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      admin: json['admin'] as bool? ?? false,
      playerType: json['player_type'] as String? ?? 'casual',
      skillScore: _double(json['skill_score']),
      goalkeeper: json['goalkeeper'] as bool? ?? false,
      createdAt: _date(json['created_at']) ?? now,
      updatedAt: _date(json['updated_at']) ?? now,
      deletedAt: _date(json['deleted_at']),
      version: json['version'] as int? ?? 1,
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
}

class SettingsProfileUpdate {
  const SettingsProfileUpdate({
    required this.name,
    required this.phone,
    required this.goalkeeper,
  });

  final String name;
  final String? phone;
  final bool goalkeeper;
}
