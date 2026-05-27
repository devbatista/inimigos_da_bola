import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../../core/widgets/skill_score_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _confirmedPlayers = [
    _PlayerViewModel(
      name: 'João Batista',
      label: 'Mensalista',
      goalkeeper: true,
    ),
    _PlayerViewModel(name: 'Rafael Lima', label: 'Avulso'),
    _PlayerViewModel(name: 'Carlos Souza', label: 'Mensalista'),
    _PlayerViewModel(name: 'Marcos Alves', label: 'Avulso', guest: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inimigos da Bola')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            const _WeeklySessionCard(),
            const SizedBox(height: AppSpacing.lg),
            Text('Confirmados', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  for (final player in _confirmedPlayers) ...[
                    PlayerTile(
                      name: player.name,
                      label: player.label,
                      goalkeeper: player.goalkeeper,
                      guest: player.guest,
                    ),
                    if (player != _confirmedPlayers.last)
                      const Divider(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _CollapsedSection(title: 'Lista de espera', count: 2),
            const SizedBox(height: AppSpacing.sm),
            const _CollapsedSection(title: 'Não vão', count: 3),
            const SizedBox(height: AppSpacing.sm),
            const _CollapsedSection(title: 'Pendentes', count: 5),
          ],
        ),
      ),
    );
  }
}

class _WeeklySessionCard extends StatelessWidget {
  const _WeeklySessionCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Racha de segunda — 03/06',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Arena X · 20:00', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              _ConfirmedCounter(confirmed: 12, maxPlayers: 20),
              SkillScoreBadge(score: 74),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(label: 'Vou!', onPressed: () {}),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(label: 'Não vou', onPressed: () {}),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Última atualização: 18:42',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ConfirmedCounter extends StatelessWidget {
  const _ConfirmedCounter({required this.confirmed, required this.maxPlayers});

  final int confirmed;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$confirmed de $maxPlayers confirmados',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _CollapsedSection extends StatelessWidget {
  const _CollapsedSection({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.sm,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title ($count)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

class _PlayerViewModel {
  const _PlayerViewModel({
    required this.name,
    required this.label,
    this.goalkeeper = false,
    this.guest = false,
  });

  final String name;
  final String label;
  final bool goalkeeper;
  final bool guest;
}
