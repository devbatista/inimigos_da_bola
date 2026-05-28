// Regras de tamanho dos times:
// - Mínimo de 3 times.
// - Cada time tem 4 ou 5 jogadores.
// - Time com goleiro precisa ter exatamente 5 (1 GK + 4 linha).
// - Se houver mais goleiros do que times, cada time recebe no máximo 1 goleiro
//   e o excedente entra como jogador de linha em times normais (a flag
//   goalkeeper continua, mas não força o tamanho extra).

class TeamSlot {
  const TeamSlot({required this.capacity, required this.requiresGoalkeeper});

  final int capacity;
  final bool requiresGoalkeeper;
}

class TeamPlan {
  const TeamPlan({required this.slots});

  final List<TeamSlot> slots;

  int get teamCount => slots.length;
}

sealed class TeamPlanResult {
  const TeamPlanResult();
}

class TeamPlanSuccess extends TeamPlanResult {
  const TeamPlanSuccess(this.plan);
  final TeamPlan plan;
}

class TeamPlanFailure extends TeamPlanResult {
  const TeamPlanFailure(this.reason);
  final String reason;
}

TeamPlanResult planTeams({
  required int participantCount,
  required int goalkeeperCount,
}) {
  if (participantCount < 12) {
    return const TeamPlanFailure('Mínimo de 12 jogadores para sortear times.');
  }

  if (goalkeeperCount < 0 || goalkeeperCount > participantCount) {
    return const TeamPlanFailure('Quantidade de goleiros inválida.');
  }

  // Procura o menor T >= 3 tal que:
  //   gkTeams = min(G, T) times com goleiro (tamanho 5)
  //   a = times de 4 sem GK = 5T - N
  //   b = times de 5 sem GK = N - 4T - gkTeams
  //   Precisa a >= 0 e b >= 0.
  for (var teamCount = 3; teamCount <= participantCount; teamCount++) {
    final goalkeeperTeams = goalkeeperCount.clamp(0, teamCount);
    final teamsOfFour = 5 * teamCount - participantCount;
    final teamsOfFive = participantCount - 4 * teamCount - goalkeeperTeams;

    if (teamsOfFour < 0 || teamsOfFive < 0) {
      continue;
    }

    return TeamPlanSuccess(
      TeamPlan(
        slots: [
          for (var i = 0; i < goalkeeperTeams; i++)
            const TeamSlot(capacity: 5, requiresGoalkeeper: true),
          for (var i = 0; i < teamsOfFour; i++)
            const TeamSlot(capacity: 4, requiresGoalkeeper: false),
          for (var i = 0; i < teamsOfFive; i++)
            const TeamSlot(capacity: 5, requiresGoalkeeper: false),
        ],
      ),
    );
  }

  // N < 12 já foi tratado. Acima disso só falha quando há goleiros demais para
  // formar times de 4/5 (ex.: 12 jogadores com 1 goleiro precisaria de 13 vagas).
  // Mínimo absoluto de jogadores para um dado G: até G=3, são G teams de 5
  // (5G) + (3-G) teams de 4 = G+12; acima disso são G teams de 5 = 5G.
  final minimumPlayers = goalkeeperCount <= 3
      ? goalkeeperCount + 12
      : 5 * goalkeeperCount;
  return TeamPlanFailure(
    'Não foi possível formar times com $participantCount jogadores '
    'e $goalkeeperCount ${goalkeeperCount == 1 ? "goleiro" : "goleiros"}. '
    'Adicione mais jogadores ou desmarque algum goleiro '
    '(seriam necessários ao menos $minimumPlayers jogadores).',
  );
}
