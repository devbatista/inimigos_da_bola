import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/stats_repository.dart';
import '../controllers/stats_controller.dart';
import '../controllers/stats_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final Map<String, _StatsDraft> _drafts = {};

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(statsControllerProvider);
    final data = controller.data;
    if (data != null) {
      _syncDrafts(data.players);
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Lançar stats'),
                Tab(text: 'Ranking'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _StatsLaunchTab(
                    controller: controller,
                    data: data,
                    drafts: _drafts,
                    onDraftChanged: _updateDraft,
                  ),
                  _LeaderboardTab(controller: controller, data: data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncDrafts(List<StatsPlayerEntry> players) {
    for (final player in players) {
      _drafts.putIfAbsent(
        player.user.id,
        () => _StatsDraft(
          goals: player.stat?.goals ?? 0,
          assists: player.stat?.assists ?? 0,
        ),
      );
    }

    final activeUserIds = players.map((player) => player.user.id).toSet();
    _drafts.removeWhere((userId, _) => !activeUserIds.contains(userId));
  }

  void _updateDraft({required String userId, int? goals, int? assists}) {
    final current = _drafts[userId] ?? const _StatsDraft();
    setState(() {
      _drafts[userId] = current.copyWith(goals: goals, assists: assists);
    });
  }
}

class _StatsLaunchTab extends StatelessWidget {
  const _StatsLaunchTab({
    required this.controller,
    required this.data,
    required this.drafts,
    required this.onDraftChanged,
  });

  final StatsController controller;
  final StatsData? data;
  final Map<String, _StatsDraft> drafts;
  final void Function({required String userId, int? goals, int? assists})
  onDraftChanged;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentData = data;
    if (currentData == null || currentData.session == null) {
      return const _EmptyState(
        title: 'Nenhum racha no cache.',
        message: 'Abra a Home com internet uma vez para carregar a sessão.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          if (controller.errorMessage != null) ...[
            _InlineMessage.danger(controller.errorMessage!),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (controller.successMessage != null) ...[
            _InlineMessage.success(controller.successMessage!),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lançar stats do racha',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Gols e assistências ficam salvos localmente e entram na fila de sincronização.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (currentData.players.isEmpty)
                  const Text('Nenhum jogador cadastrado confirmado no cache.')
                else ...[
                  for (final player in currentData.players) ...[
                    _StatsInputRow(
                      entry: player,
                      draft: drafts[player.user.id] ?? const _StatsDraft(),
                      onChanged: onDraftChanged,
                    ),
                    if (player != currentData.players.last)
                      const Divider(height: AppSpacing.lg),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton.primary(
                    label: controller.saving
                        ? 'Salvando...'
                        : 'Salvar stats do racha',
                    onPressed: controller.saving
                        ? null
                        : () => controller.save(_inputs(currentData.players)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<StatsInput> _inputs(List<StatsPlayerEntry> players) {
    return [
      for (final player in players)
        StatsInput(
          userId: player.user.id,
          goals: drafts[player.user.id]?.goals ?? 0,
          assists: drafts[player.user.id]?.assists ?? 0,
        ),
    ];
  }
}

class _StatsInputRow extends StatelessWidget {
  const _StatsInputRow({
    required this.entry,
    required this.draft,
    required this.onChanged,
  });

  final StatsPlayerEntry entry;
  final _StatsDraft draft;
  final void Function({required String userId, int? goals, int? assists})
  onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.user.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NumberField(
          label: 'Gols',
          value: draft.goals,
          onChanged: (value) => onChanged(userId: entry.user.id, goals: value),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NumberField(
          label: 'Assist.',
          value: draft.assists,
          onChanged: (value) =>
              onChanged(userId: entry.user.id, assists: value),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: '$value',
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
        onChanged: (text) {
          final parsed = int.tryParse(text);
          onChanged(parsed == null ? 0 : parsed.clamp(0, 99));
        },
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.controller, required this.data});

  final StatsController controller;
  final StatsData? data;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = data?.leaderboard ?? const <LeaderboardEntry>[];
    if (entries.isEmpty) {
      return const _EmptyState(
        title: 'Ranking vazio.',
        message: 'As stats salvas no aparelho aparecerão aqui.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          AppCard(
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _LeaderboardRow(position: index + 1, entry: entries[index]),
                  if (index < entries.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.position, required this.entry});

  final int position;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: AppSpacing.xl,
          child: Text(
            '$positionº',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(entry.user.name, style: theme.textTheme.bodyLarge),
        ),
        _StatPill(label: 'G', value: entry.goals),
        const SizedBox(width: AppSpacing.sm),
        _StatPill(label: 'A', value: entry.assists),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.leather.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text('$label $value'),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage._({
    required this.message,
    required this.color,
    required this.icon,
  });

  factory _InlineMessage.success(String message) {
    return _InlineMessage._(
      message: message,
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  factory _InlineMessage.danger(String message) {
    return _InlineMessage._(
      message: message,
      color: AppColors.danger,
      icon: Icons.error_outline,
    );
  }

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.subtle,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(message),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsDraft {
  const _StatsDraft({this.goals = 0, this.assists = 0});

  final int goals;
  final int assists;

  _StatsDraft copyWith({int? goals, int? assists}) {
    return _StatsDraft(
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
    );
  }
}
