import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skill_rating_slider.dart';
import '../../data/skill_ratings_repository.dart';
import '../controllers/skill_ratings_providers.dart';

class SkillRatingsScreen extends ConsumerWidget {
  const SkillRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(skillRatingsControllerProvider);
    final data = controller.data;

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliar jogadores')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(skillRatingsControllerProvider).load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (controller.loading && data == null)
                const _LoadingCard()
              else if (data == null)
                _ErrorCard(
                  message:
                      controller.errorMessage ?? 'Não foi possível carregar.',
                  onRetry: () =>
                      ref.read(skillRatingsControllerProvider).load(),
                )
              else if (data.evaluables.isEmpty)
                const AppCard(child: Text('Nenhum jogador para avaliar.'))
              else ...[
                AppCard(
                  child: Text(
                    'Dê uma nota de 0 a 100 para cada jogador. Você poderá '
                    'alterar a nota dada para um mesmo jogador após 1 mês.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineError(message: controller.errorMessage!),
                ],
                const SizedBox(height: AppSpacing.md),
                _EvaluablesList(data: data),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluablesList extends ConsumerWidget {
  const _EvaluablesList({required this.data});

  final SkillRatingsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        children: [
          for (final player in data.evaluables) ...[
            _EvaluableTile(
              player: player,
              rating: data.ratingsByEvaluatedId[player.id],
              onTap: () => _openSheet(context, ref, player),
            ),
            if (player != data.evaluables.last)
              const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    User player,
  ) async {
    final rating = data.ratingsByEvaluatedId[player.id];
    ref.read(skillRatingsControllerProvider).clearSubmitError();

    await AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return _RatingSheet(player: player, previousRating: rating);
      },
    );
  }
}

class _EvaluableTile extends StatelessWidget {
  const _EvaluableTile({
    required this.player,
    required this.rating,
    required this.onTap,
  });

  final User player;
  final SkillRating? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reevaluationAt = rating?.updatedAt.add(const Duration(days: 30));
    final blocked =
        reevaluationAt != null && reevaluationAt.isAfter(DateTime.now());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !blocked,
      onTap: blocked ? null : onTap,
      title: Text(player.name, style: theme.textTheme.bodyMedium),
      subtitle: blocked
          ? Text(
              'Disponível para nova nota em ${_date(reevaluationAt)}',
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Icon(blocked ? Icons.lock_outline : Icons.chevron_right),
    );
  }
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({required this.player, required this.previousRating});

  final User player;
  final SkillRating? previousRating;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  // Slider sempre começa em 50: não mostrar nota prévia evita ancoragem e
  // mantém o voto totalmente anônimo, mesmo do próprio avaliador.
  int _score = 50;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(skillRatingsControllerProvider);
    final reevaluationAt = widget.previousRating?.updatedAt.add(
      const Duration(days: 30),
    );
    final blockedLocally =
        reevaluationAt != null && reevaluationAt.isAfter(DateTime.now());
    final submitDisabled = controller.submitting || blockedLocally;

    return AppBottomSheet(
      title: widget.player.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkillRatingSlider(
            value: _score,
            onChanged: controller.submitting
                ? null
                : (next) => setState(() => _score = next),
          ),
          if (blockedLocally) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Você poderá enviar uma nova nota para este jogador em '
              '${_date(reevaluationAt)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (controller.submitErrorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineError(message: controller.submitErrorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: controller.submitting ? 'Enviando...' : 'Enviar nota',
            onPressed: submitDisabled ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await ref
        .read(skillRatingsControllerProvider)
        .submit(evaluatedUserId: widget.player.id, score: _score);

    if (!mounted) {
      return;
    }

    if (success) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Nota enviada.')));
    }
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

String _date(DateTime date) {
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
