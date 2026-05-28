import 'package:drift/drift.dart';

import '../../../core/api/clients/skill_ratings_api_client.dart';
import '../../../core/api/clients/sync_api_client.dart';
import '../../../core/api/clients/users_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/skill_ratings_dao.dart';
import '../../../core/db/daos/users_dao.dart';

class SkillRatingsRepository {
  const SkillRatingsRepository({
    required SkillRatingsApiClient skillRatingsApiClient,
    required UsersApiClient usersApiClient,
    required SyncApiClient syncApiClient,
    required SkillRatingsDao skillRatingsDao,
    required UsersDao usersDao,
  }) : _skillRatingsApiClient = skillRatingsApiClient,
       _usersApiClient = usersApiClient,
       _syncApiClient = syncApiClient,
       _skillRatingsDao = skillRatingsDao,
       _usersDao = usersDao;

  final SkillRatingsApiClient _skillRatingsApiClient;
  final UsersApiClient _usersApiClient;
  final SyncApiClient _syncApiClient;
  final SkillRatingsDao _skillRatingsDao;
  final UsersDao _usersDao;

  Future<SkillRatingsData> load() async {
    final currentUserJson = await _usersApiClient.me();
    final currentUserId = currentUserJson['id'] as String;
    final currentUserEmail = currentUserJson['email'] as String;
    await _upsertUser(currentUserJson);

    final syncJson = await _syncApiClient.pull(entities: const ['users']);
    final entities = syncJson['entities'];
    if (entities is Map<String, dynamic>) {
      for (final json in _entityList(entities, 'users')) {
        await _upsertUser(json);
      }
    }

    return _readData(
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
  }

  Future<SkillRatingsData> submit({
    required String currentUserId,
    required String currentUserEmail,
    required String evaluatedUserId,
    required int score,
  }) async {
    final json = await _skillRatingsApiClient.createOrUpdate(
      evaluatedUserId: evaluatedUserId,
      score: score,
    );
    await _upsertRating(json);

    return _readData(
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
  }

  Future<SkillRatingsData> _readData({
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final users = await _usersDao.listActiveUsers();
    final ratings = await _skillRatingsDao
        .watchRatingsGivenBy(currentUserId)
        .first;

    // Filtra por id E por email (case-insensitive) como defesa em profundidade:
    // se o backend foi re-seedado e há registros órfãos com o mesmo email mas
    // id antigo no cache local, o casamento por email ainda exclui o próprio.
    final normalizedEmail = currentUserEmail.toLowerCase();
    final evaluables =
        users
            .where(
              (user) =>
                  user.id != currentUserId &&
                  user.email.toLowerCase() != normalizedEmail,
            )
            .toList()
          ..sort((first, second) => first.name.compareTo(second.name));

    return SkillRatingsData(
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
      evaluables: evaluables,
      ratingsByEvaluatedId: {
        for (final rating in ratings) rating.evaluatedUserId: rating,
      },
    );
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

  Future<void> _upsertRating(Map<String, dynamic> json) {
    final now = DateTime.now();

    return _skillRatingsDao.upsertSkillRating(
      SkillRatingsCompanion.insert(
        id: json['id'] as String,
        evaluatorUserId: json['evaluator_user_id'] as String,
        evaluatedUserId: json['evaluated_user_id'] as String,
        score: json['score'] as int,
        createdAt: _date(json['created_at']) ?? now,
        updatedAt: _date(json['updated_at']) ?? now,
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
}

class SkillRatingsData {
  const SkillRatingsData({
    required this.currentUserId,
    required this.currentUserEmail,
    required this.evaluables,
    required this.ratingsByEvaluatedId,
  });

  final String currentUserId;
  final String currentUserEmail;
  final List<User> evaluables;
  final Map<String, SkillRating> ratingsByEvaluatedId;
}
