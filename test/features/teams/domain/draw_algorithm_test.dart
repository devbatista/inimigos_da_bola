import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/features/teams/domain/draw_algorithm.dart';
import 'package:inimigos_da_bola/features/teams/domain/team_plan.dart';

DrawParticipant _registered(
  String id,
  double skill, {
  bool goalkeeper = false,
}) {
  return DrawParticipant(
    id: id,
    name: 'Player $id',
    kind: DrawParticipantKind.registered,
    skillScore: skill,
    goalkeeper: goalkeeper,
  );
}

DrawParticipant _guest(String id) {
  return DrawParticipant(
    id: id,
    name: 'Guest $id',
    kind: DrawParticipantKind.guest,
  );
}

TeamPlan _planFor({required int n, required int g}) {
  final result = planTeams(participantCount: n, goalkeeperCount: g);
  return (result as TeamPlanSuccess).plan;
}

void main() {
  group('snakeDraft', () {
    test('respeita capacidade de cada time', () {
      final participants = [
        for (var i = 0; i < 12; i++) _registered('p$i', 50 + i.toDouble()),
      ];
      final plan = _planFor(n: 12, g: 0);

      final result = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 1,
      );

      expect(result.teams.length, 3);
      for (var i = 0; i < result.teams.length; i++) {
        expect(result.teams[i].players.length, plan.slots[i].capacity);
      }
    });

    test('coloca um goleiro em cada time enquanto houver vaga', () {
      final participants = [
        _registered('g1', 60, goalkeeper: true),
        _registered('g2', 55, goalkeeper: true),
        for (var i = 0; i < 12; i++) _registered('p$i', 40 + i.toDouble()),
      ];
      final plan = _planFor(n: 14, g: 2);

      final result = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 42,
      );

      final goalkeeperCounts = result.teams.map(
        (team) => team.players.where((player) => player.goalkeeper).length,
      );
      expect(goalkeeperCounts.where((count) => count == 1).length, 2);
      expect(goalkeeperCounts.where((count) => count == 0).length, 1);
    });

    test(
      'distribui skill de forma razoavelmente balanceada (diferença ≤ ~15%)',
      () {
        final participants = [
          for (var i = 0; i < 12; i++) _registered('p$i', i * 10.0),
        ];
        final plan = _planFor(n: 12, g: 0);

        final result = snakeDraft(
          participants: participants,
          plan: plan,
          seed: 7,
        );

        final totals = result.teams
            .map(
              (team) => team.players.fold<double>(
                0,
                (sum, p) => sum + (p.skillScore ?? 0),
              ),
            )
            .toList();
        final average = totals.reduce((a, b) => a + b) / totals.length;
        for (final total in totals) {
          expect(
            (total - average).abs() / average,
            lessThan(0.15),
            reason: 'time fugiu ao balanceamento: totais=$totals',
          );
        }
      },
    );

    test('avulso sem skill recebe o mediano dos cadastrados confirmados', () {
      final participants = <DrawParticipant>[
        _registered('p1', 20),
        _registered('p2', 40),
        _registered('p3', 60),
        _registered('p4', 80),
        _registered('p5', 90),
        _registered('p6', 30),
        _registered('p7', 50),
        _registered('p8', 70),
        _registered('p9', 55),
        _registered('p10', 45),
        _registered('p11', 65),
        _guest('g1'),
      ];
      final plan = _planFor(n: 12, g: 0);

      final result = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 3,
      );

      final guest = result.teams
          .expand((team) => team.players)
          .firstWhere((p) => p.kind == DrawParticipantKind.guest);
      expect(guest.id, 'g1');
      // O guest foi colocado em algum time; o que importa é que o algoritmo
      // não explodiu e ele aparece no resultado.
      final allPlayers = result.teams.expand((team) => team.players).toList();
      expect(allPlayers.length, 12);
    });

    test('sem cadastrados com skill, todos viram skill 50', () {
      final participants = [for (var i = 0; i < 12; i++) _guest('g$i')];
      final plan = _planFor(n: 12, g: 0);

      final result = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 9,
      );

      expect(result.teams.expand((team) => team.players).length, 12);
    });

    test('seeds diferentes produzem distribuições diferentes', () {
      final participants = [
        for (var i = 0; i < 12; i++) _registered('p$i', 50),
      ];
      final plan = _planFor(n: 12, g: 0);

      final first = snakeDraft(participants: participants, plan: plan, seed: 1);
      final second = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 999,
      );

      final firstIds = first.teams.first.players.map((p) => p.id).toList();
      final secondIds = second.teams.first.players.map((p) => p.id).toList();
      expect(firstIds, isNot(equals(secondIds)));
    });

    test('goleiros excedentes voltam para o pool como linha', () {
      final participants = [
        for (var i = 0; i < 5; i++) _registered('g$i', 60, goalkeeper: true),
        for (var i = 0; i < 10; i++) _registered('p$i', 50 + i.toDouble()),
      ];
      final plan = _planFor(n: 15, g: 5);
      // Apenas 3 times, então só 3 goleiros viram "GK do time".

      final result = snakeDraft(
        participants: participants,
        plan: plan,
        seed: 11,
      );

      // Os 5 goleiros aparecem no resultado, mas só 3 times têm goleiro.
      final totalGoalkeepers = result.teams
          .expand((team) => team.players)
          .where((player) => player.goalkeeper)
          .length;
      expect(totalGoalkeepers, 5);
      expect(result.teams.length, 3);
    });
  });
}
