import 'dart:math';

import 'team_plan.dart';

enum DrawParticipantKind { registered, guest, temporary }

class DrawParticipant {
  const DrawParticipant({
    required this.id,
    required this.name,
    required this.kind,
    this.skillScore,
    this.goalkeeper = false,
  });

  final String id;
  final String name;
  final DrawParticipantKind kind;
  final double? skillScore;
  final bool goalkeeper;
}

class DrawTeam {
  const DrawTeam({required this.name, required this.players});

  final String name;
  final List<DrawParticipant> players;
}

class DrawResult {
  const DrawResult({required this.teams, required this.seed});

  final List<DrawTeam> teams;
  final int seed;
}

DrawResult snakeDraft({
  required List<DrawParticipant> participants,
  required TeamPlan plan,
  required int seed,
}) {
  final random = Random(seed);

  final medianSkill = _medianSkillOfRegistered(participants);
  double effectiveSkill(DrawParticipant participant) {
    if (participant.kind == DrawParticipantKind.registered &&
        participant.skillScore != null) {
      return participant.skillScore!;
    }
    return medianSkill;
  }

  final teams = List.generate(plan.teamCount, (_) => <DrawParticipant>[]);
  final capacities = plan.slots.map((slot) => slot.capacity).toList();

  // Distribui goleiros: um por time enquanto possível. Excedentes voltam para
  // o pool de jogadores normais e entram via snake draft como linha.
  final goalkeepers = participants.where((p) => p.goalkeeper).toList()
    ..shuffle(random);
  final remainingGoalkeepers = <DrawParticipant>[];
  for (var i = 0; i < goalkeepers.length; i++) {
    if (i < plan.teamCount) {
      teams[i].add(goalkeepers[i]);
    } else {
      remainingGoalkeepers.add(goalkeepers[i]);
    }
  }

  // Jogadores de linha (inclui goleiros excedentes) ordenados por skill desc.
  // Desempate aleatório dentro de skills próximos (mesma faixa inteira) para
  // dar variabilidade ao "Refazer sorteio".
  final linePlayers = <DrawParticipant>[
    ...participants.where((p) => !p.goalkeeper),
    ...remainingGoalkeepers,
  ]..shuffle(random);
  linePlayers.sort((first, second) {
    final compare = effectiveSkill(second).compareTo(effectiveSkill(first));
    if (compare != 0) {
      return compare;
    }
    return 0;
  });

  // Snake draft, pulando times que já estão cheios. Boundary handling: no fim
  // de uma volta, o mesmo time pega de novo (padrão clássico do snake).
  var direction = 1;
  var index = 0;

  bool isFull(int teamIndex) =>
      teams[teamIndex].length >= capacities[teamIndex];

  int advance(int from) {
    var next = from + direction;
    if (next >= plan.teamCount) {
      direction = -1;
      next = plan.teamCount - 1;
    } else if (next < 0) {
      direction = 1;
      next = 0;
    }
    return next;
  }

  for (final player in linePlayers) {
    // Encontra próximo time com vaga, varrendo conforme a direção do snake.
    var guard = 0;
    while (isFull(index)) {
      index = advance(index);
      guard++;
      if (guard > plan.teamCount * 2) {
        break;
      }
    }
    teams[index].add(player);
    index = advance(index);
  }

  return DrawResult(
    teams: [
      for (var i = 0; i < teams.length; i++)
        DrawTeam(name: _defaultTeamName(i), players: teams[i]),
    ],
    seed: seed,
  );
}

double _medianSkillOfRegistered(List<DrawParticipant> participants) {
  final scores =
      participants
          .where(
            (p) =>
                p.kind == DrawParticipantKind.registered &&
                p.skillScore != null,
          )
          .map((p) => p.skillScore!)
          .toList()
        ..sort();

  if (scores.isEmpty) {
    return 50;
  }

  final middle = scores.length ~/ 2;
  if (scores.length.isOdd) {
    return scores[middle];
  }
  return (scores[middle - 1] + scores[middle]) / 2;
}

String _defaultTeamName(int index) {
  const letters = 'ABCDEFGHIJ';
  if (index < letters.length) {
    return 'Time ${letters[index]}';
  }
  return 'Time ${index + 1}';
}
