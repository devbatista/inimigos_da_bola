// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_ratings_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillRatingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $SkillRatingsTable get skillRatings => attachedDatabase.skillRatings;
  SkillRatingsDaoManager get managers => SkillRatingsDaoManager(this);
}

class SkillRatingsDaoManager {
  final _$SkillRatingsDaoMixin _db;
  SkillRatingsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$SkillRatingsTableTableManager get skillRatings =>
      $$SkillRatingsTableTableManager(_db.attachedDatabase, _db.skillRatings);
}
