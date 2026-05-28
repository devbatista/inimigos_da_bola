import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../../core/widgets/skill_score_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _confirmedPlayers = [
    _PlayerViewModel(
      name: 'João Batista',
      playerType: _PlayerType.monthly,
      goalkeeper: true,
    ),
    _PlayerViewModel(name: 'Rafael Lima', playerType: _PlayerType.casual),
    _PlayerViewModel(name: 'Carlos Souza', playerType: _PlayerType.monthly),
    _PlayerViewModel(
      name: 'Marcos Alves',
      playerType: _PlayerType.casual,
      guest: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
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
          Text(
            l10n.confirmedSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                for (final player in _confirmedPlayers) ...[
                  PlayerTile(
                    name: player.name,
                    label: player.label(l10n),
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
          _CollapsedSection(title: l10n.waitlistSectionTitle, count: 2),
          const SizedBox(height: AppSpacing.sm),
          _CollapsedSection(title: l10n.declinedSectionTitle, count: 3),
          const SizedBox(height: AppSpacing.sm),
          _CollapsedSection(title: l10n.pendingSectionTitle, count: 5),
        ],
      ),
    );
  }
}

class _WeeklySessionCard extends StatelessWidget {
  const _WeeklySessionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weeklySessionTitle,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.weeklySessionPlaceTime,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ConfirmedCounter(confirmed: 12, maxPlayers: 20),
              SkillScoreBadge(score: 74),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: l10n.goingButtonLabel,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: l10n.notGoingButtonLabel,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.lastUpdatedLabel,
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
    final l10n = AppLocalizations.of(context);

    return Text(
      l10n.confirmedCounter(confirmed, maxPlayers),
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
    required this.playerType,
    this.goalkeeper = false,
    this.guest = false,
  });

  final String name;
  final _PlayerType playerType;
  final bool goalkeeper;
  final bool guest;

  String label(AppLocalizations l10n) {
    return switch (playerType) {
      _PlayerType.monthly => l10n.monthlyPlayerLabel,
      _PlayerType.casual => l10n.casualPlayerLabel,
    };
  }
}

enum _PlayerType { monthly, casual }
