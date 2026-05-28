import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/features/teams/domain/team_plan.dart';

void main() {
  group('planTeams - exemplos do produto', () {
    test('12 jogadores sem goleiro: 3 times de 4', () {
      final result = planTeams(participantCount: 12, goalkeeperCount: 0);
      expect(result, isA<TeamPlanSuccess>());
      final plan = (result as TeamPlanSuccess).plan;
      expect(plan.teamCount, 3);
      expect(plan.slots.map((slot) => slot.capacity), [4, 4, 4]);
      expect(plan.slots.every((slot) => !slot.requiresGoalkeeper), isTrue);
    });

    test('13 jogadores sem goleiro: 2 times de 4 + 1 time de 5', () {
      final result = planTeams(participantCount: 13, goalkeeperCount: 0);
      final plan = (result as TeamPlanSuccess).plan;
      expect(plan.teamCount, 3);
      final sizes = plan.slots.map((slot) => slot.capacity).toList()..sort();
      expect(sizes, [4, 4, 5]);
    });

    test('16 jogadores sem goleiro: 4 times de 4', () {
      final result = planTeams(participantCount: 16, goalkeeperCount: 0);
      final plan = (result as TeamPlanSuccess).plan;
      expect(plan.teamCount, 4);
      expect(plan.slots.map((slot) => slot.capacity), [4, 4, 4, 4]);
    });
  });

  group('planTeams - goleiros', () {
    test('13 jogadores com 1 goleiro: 1 time de 5 (GK) + 2 times de 4', () {
      final result = planTeams(participantCount: 13, goalkeeperCount: 1);
      final plan = (result as TeamPlanSuccess).plan;
      expect(plan.teamCount, 3);
      final goalkeeperSlots = plan.slots
          .where((slot) => slot.requiresGoalkeeper)
          .toList();
      expect(goalkeeperSlots.length, 1);
      expect(goalkeeperSlots.first.capacity, 5);
      final normal = plan.slots
          .where((slot) => !slot.requiresGoalkeeper)
          .toList();
      expect(normal.length, 2);
      expect(normal.every((slot) => slot.capacity == 4), isTrue);
    });

    test('15 jogadores com 3 goleiros: 3 times de 5 todos com GK', () {
      final result = planTeams(participantCount: 15, goalkeeperCount: 3);
      final plan = (result as TeamPlanSuccess).plan;
      expect(plan.teamCount, 3);
      expect(plan.slots.where((slot) => slot.requiresGoalkeeper).length, 3);
      expect(plan.slots.every((slot) => slot.capacity == 5), isTrue);
    });
  });

  group('planTeams - bloqueios', () {
    test('Menos de 12 jogadores bloqueia com mensagem clara', () {
      final result = planTeams(participantCount: 10, goalkeeperCount: 0);
      expect(result, isA<TeamPlanFailure>());
      expect((result as TeamPlanFailure).reason, contains('12 jogadores'));
    });

    test('12 jogadores com 1 goleiro não fecha conta e explica o motivo', () {
      final result = planTeams(participantCount: 12, goalkeeperCount: 1);
      expect(result, isA<TeamPlanFailure>());
      final reason = (result as TeamPlanFailure).reason;
      expect(reason, contains('Não foi possível'));
      expect(reason, contains('13'));
    });
  });
}
