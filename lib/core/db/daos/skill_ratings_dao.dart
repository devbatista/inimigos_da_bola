import 'package:drift/drift.dart';

import '../app_database.dart';

part 'skill_ratings_dao.g.dart';

@DriftAccessor(tables: [SkillRatings])
class SkillRatingsDao extends DatabaseAccessor<AppDatabase>
    with _$SkillRatingsDaoMixin {
  SkillRatingsDao(super.db);

  Stream<List<SkillRating>> watchRatingsGivenBy(String evaluatorUserId) {
    return (select(skillRatings)..where(
          (rating) =>
              rating.evaluatorUserId.equals(evaluatorUserId) &
              rating.deletedAt.isNull(),
        ))
        .watch();
  }

  Future<void> upsertSkillRating(SkillRatingsCompanion skillRating) {
    return into(skillRatings).insertOnConflictUpdate(skillRating);
  }
}
