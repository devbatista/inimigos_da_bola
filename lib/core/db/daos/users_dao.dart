import 'package:drift/drift.dart';

import '../app_database.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<List<User>> watchActiveUsers() {
    return (select(users)..where((user) => user.deletedAt.isNull())).watch();
  }

  Future<List<User>> listActiveUsers() {
    return (select(users)..where((user) => user.deletedAt.isNull())).get();
  }

  Future<void> upsertUser(UsersCompanion user) {
    return into(users).insertOnConflictUpdate(user);
  }
}
