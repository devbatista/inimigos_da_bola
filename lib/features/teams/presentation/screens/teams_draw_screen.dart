import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/draw_algorithm.dart';
import '../controllers/teams_draw_controller.dart';
import '../controllers/teams_draw_providers.dart';

class TeamsDrawScreen extends ConsumerWidget {
  const TeamsDrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(teamsDrawControllerProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(teamsDrawControllerProvider).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            if (controller.loading && controller.participants.isEmpty)
              const _LoadingCard()
            else if (controller.errorMessage != null &&
                controller.participants.isEmpty)
              _ErrorCard(
                message: controller.errorMessage!,
                onRetry: () => ref.read(teamsDrawControllerProvider).load(),
              )
            else ...[
              _DrawActionsCard(controller: controller),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _InlineError(message: controller.errorMessage!),
              ],
              if (controller.planFailure != null) ...[
                const SizedBox(height: AppSpacing.md),
                _InlineError(message: controller.planFailure!.reason),
              ],
              const SizedBox(height: AppSpacing.md),
              if (controller.result != null) ...[
                _ResultCards(result: controller.result!),
                const SizedBox(height: AppSpacing.lg),
              ],
              _ParticipantsCard(controller: controller),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawActionsCard extends StatelessWidget {
  const _DrawActionsCard({required this.controller});

  final TeamsDrawController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDraw = controller.participantCount >= 12;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sorteio de times',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${controller.participantCount} participantes · '
            '${controller.goalkeeperCount} '
            '${controller.goalkeeperCount == 1 ? "goleiro" : "goleiros"}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            label: controller.result == null ? 'Sortear' : 'Refazer sorteio',
            onPressed: canDraw ? controller.draw : null,
          ),
          if (controller.result != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Limpar resultado',
              onPressed: controller.clearResult,
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantsCard extends ConsumerWidget {
  const _ParticipantsCard({required this.controller});

  final TeamsDrawController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final participants = controller.participants;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Participantes (${participants.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text('Avulso'),
                onPressed: () => _showAddTemporaryDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (participants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Nenhum participante confirmado ainda.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            for (final participant in participants) ...[
              _ParticipantTile(
                participant: participant,
                onRemove: () => controller.removeParticipant(participant.id),
              ),
              if (participant != participants.last)
                const Divider(height: AppSpacing.lg),
            ],
        ],
      ),
    );
  }

  Future<void> _showAddTemporaryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    var goalkeeper = false;
    String? nameError;

    final added = await showDialog<_TemporaryInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar avulso temporário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      errorText: nameError,
                    ),
                    onChanged: (_) {
                      if (nameError != null) {
                        setState(() => nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('É goleiro'),
                    value: goalkeeper,
                    onChanged: (value) =>
                        setState(() => goalkeeper = value ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() => nameError = 'Informe o nome.');
                      return;
                    }
                    Navigator.of(
                      context,
                    ).pop(_TemporaryInput(name: name, goalkeeper: goalkeeper));
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (added == null) {
      return;
    }

    ref
        .read(teamsDrawControllerProvider)
        .addTemporaryParticipant(
          name: added.name,
          goalkeeper: added.goalkeeper,
        );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.onRemove});

  final DrawParticipant participant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(participant.name, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    _kindLabel(participant.kind),
                    style: theme.textTheme.labelSmall,
                  ),
                  if (participant.goalkeeper)
                    Text(
                      '· Goleiro',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.leather,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remover do sorteio',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ],
    );
  }

  String _kindLabel(DrawParticipantKind kind) {
    return switch (kind) {
      DrawParticipantKind.registered => 'Confirmado',
      DrawParticipantKind.guest => 'Avulso (admin)',
      DrawParticipantKind.temporary => 'Avulso temporário',
    };
  }
}

class _ResultCards extends ConsumerWidget {
  const _ResultCards({required this.result});

  final DrawResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < result.teams.length; i++) ...[
          _TeamCard(
            team: result.teams[i],
            onRename: (name) =>
                ref.read(teamsDrawControllerProvider).renameTeam(i, name),
          ),
          if (i < result.teams.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onRename});

  final DrawTeam team;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.leather,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar nome do time',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showRenameDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final player in team.players)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(player.name, style: theme.textTheme.bodyMedium),
                  ),
                  if (player.goalkeeper) const _GoalkeeperBadge(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final controller = TextEditingController(text: team.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome do time'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(text);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) {
      onRename(result);
    }
  }
}

class _GoalkeeperBadge extends StatelessWidget {
  const _GoalkeeperBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.leather),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'GOL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.leather,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InlineError(message: message),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(label: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _TemporaryInput {
  const _TemporaryInput({required this.name, required this.goalkeeper});

  final String name;
  final bool goalkeeper;
}
