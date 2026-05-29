import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/game_mode_controller.dart';
import '../controllers/game_mode_providers.dart';

class GameModeScreen extends ConsumerStatefulWidget {
  const GameModeScreen({super.key});

  @override
  ConsumerState<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends ConsumerState<GameModeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(gameModeControllerProvider);
    final snapshot = controller.snapshot;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          _TimerCard(snapshot: snapshot, controller: controller),
          const SizedBox(height: AppSpacing.md),
          _ScoreboardCard(snapshot: snapshot, controller: controller),
          if (snapshot.isFinished) ...[
            const SizedBox(height: AppSpacing.md),
            _FinishedBanner(snapshot: snapshot),
          ],
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.snapshot, required this.controller});

  final GameModeSnapshot snapshot;
  final GameModeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<GameTimerMode>(
            segments: const [
              ButtonSegment(
                value: GameTimerMode.countDown,
                icon: Icon(Icons.timer_outlined),
                label: Text('08:00'),
              ),
              ButtonSegment(
                value: GameTimerMode.countUp,
                icon: Icon(Icons.av_timer),
                label: Text('Livre'),
              ),
            ],
            selected: {snapshot.state.timerMode},
            onSelectionChanged: (selection) {
              controller.setTimerMode(selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              _formatDuration(snapshot.displayDuration),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: snapshot.finishedByTime ? AppColors.danger : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: snapshot.state.isRunning ? 'Pausar' : 'Iniciar',
                  onPressed: snapshot.state.isRunning
                      ? controller.pause
                      : controller.start,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: 'Resetar',
                  onPressed: controller.reset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreboardCard extends StatelessWidget {
  const _ScoreboardCard({required this.snapshot, required this.controller});

  final GameModeSnapshot snapshot;
  final GameModeController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamScorePanel(
              name: snapshot.state.teamAName,
              score: snapshot.state.teamAScore,
              isWinnerByScore: snapshot.state.teamAScore >= 2,
              onRename: () => _showRenameDialog(
                context: context,
                title: 'Renomear Time A',
                currentName: snapshot.state.teamAName,
                onSave: controller.renameTeamA,
              ),
              onIncrement: controller.incrementTeamA,
              onDecrement: controller.decrementTeamA,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('x', style: Theme.of(context).textTheme.displayMedium),
          ),
          Expanded(
            child: _TeamScorePanel(
              name: snapshot.state.teamBName,
              score: snapshot.state.teamBScore,
              isWinnerByScore: snapshot.state.teamBScore >= 2,
              onRename: () => _showRenameDialog(
                context: context,
                title: 'Renomear Time B',
                currentName: snapshot.state.teamBName,
                onSave: controller.renameTeamB,
              ),
              onIncrement: controller.incrementTeamB,
              onDecrement: controller.decrementTeamB,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog({
    required BuildContext context,
    required String title,
    required String currentName,
    required ValueChanged<String> onSave,
  }) async {
    final textController = TextEditingController(text: currentName);
    String? errorText;

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome do time',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = textController.text.trim();
                    if (value.isEmpty) {
                      setState(() => errorText = 'Informe o nome do time.');
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();

    if (name != null) {
      onSave(name);
    }
  }
}

class _TeamScorePanel extends StatelessWidget {
  const _TeamScorePanel({
    required this.name,
    required this.score,
    required this.isWinnerByScore,
    required this.onRename,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String name;
  final int score;
  final bool isWinnerByScore;
  final VoidCallback onRename;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onRename,
          icon: const Icon(Icons.edit_outlined),
          label: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: isWinnerByScore ? AppColors.success.subtle : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Text(
                '$score',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: isWinnerByScore ? AppColors.success : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: IconButton.filled(
                tooltip: 'Adicionar gol',
                onPressed: onIncrement,
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: IconButton.outlined(
                tooltip: 'Remover gol',
                onPressed: score > 0 ? onDecrement : null,
                icon: const Icon(Icons.remove),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FinishedBanner extends StatelessWidget {
  const _FinishedBanner({required this.snapshot});

  final GameModeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = snapshot.finishedByScore
        ? 'Fim por 2 gols.'
        : 'Fim por 8 minutos.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.subtle,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(100).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
