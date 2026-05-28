import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../../core/widgets/skill_score_badge.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/attendance_repository.dart';
import '../controllers/attendance_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(attendanceControllerProvider);
    final data = controller.data;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(attendanceControllerProvider).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            if (controller.loading && data == null)
              const _LoadingCard()
            else if (data == null)
              _ErrorCard(
                message:
                    controller.errorMessage ?? 'Não foi possível carregar.',
                onRetry: () => ref.read(attendanceControllerProvider).load(),
              )
            else ...[
              _WeeklySessionCard(data: data),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _InlineError(message: controller.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _AttendanceSection(
                title: AppLocalizations.of(context).confirmedSectionTitle,
                attendances: data.mainConfirmed,
                data: data,
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AttendanceSection(
                title: AppLocalizations.of(context).waitlistSectionTitle,
                attendances: data.waitlisted,
                data: data,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AttendanceSection(
                title: AppLocalizations.of(context).declinedSectionTitle,
                attendances: data.declined,
                data: data,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AttendanceSection(
                title: AppLocalizations.of(context).pendingSectionTitle,
                attendances: data.pending,
                data: data,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklySessionCard extends ConsumerWidget {
  const _WeeklySessionCard({required this.data});

  final AttendanceHomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.watch(attendanceControllerProvider);
    final scheduledAt = data.session.scheduledAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sessionTitle(scheduledAt),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Arena X · ${_time(scheduledAt)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ConfirmedCounter(
                confirmed: data.mainConfirmed.length,
                maxPlayers: data.session.maxPlayers,
              ),
              SkillScoreBadge(score: data.currentUser.skillScore?.round() ?? 0),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: controller.submitting
                      ? 'Atualizando...'
                      : l10n.goingButtonLabel,
                  onPressed: controller.submitting
                      ? null
                      : () => ref.read(attendanceControllerProvider).confirm(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: l10n.notGoingButtonLabel,
                  onPressed: controller.submitting
                      ? null
                      : () => ref.read(attendanceControllerProvider).decline(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const StatusBanner(status: StatusBannerStatus.synced),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Última atualização: ${_time(data.updatedAt)}',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
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

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.title,
    required this.attendances,
    required this.data,
    this.expanded = false,
  });

  final String title;
  final List<Attendance> attendances;
  final AttendanceHomeData data;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.sm,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
        title: Text(
          '$title (${attendances.length})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          if (attendances.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nenhum jogador.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final attendance in attendances) ...[
              PlayerTile(
                name: _attendanceName(attendance, data),
                label: _attendanceLabel(attendance, data, context),
                goalkeeper: _attendanceGoalkeeper(attendance, data),
                guest: attendance.kind == 'guest',
              ),
              if (attendance != attendances.last)
                const Divider(height: AppSpacing.lg),
            ],
        ],
      ),
    );
  }

  String _attendanceName(Attendance attendance, AttendanceHomeData data) {
    if (attendance.kind == 'guest') {
      return attendance.guestName ?? 'Avulso';
    }

    return data.usersById[attendance.userId]?.name ?? 'Jogador';
  }

  String _attendanceLabel(
    Attendance attendance,
    AttendanceHomeData data,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);
    if (attendance.kind == 'guest') {
      return l10n.casualPlayerLabel;
    }

    final playerType = data.usersById[attendance.userId]?.playerType;
    return playerType == 'monthly'
        ? l10n.monthlyPlayerLabel
        : l10n.casualPlayerLabel;
  }

  bool _attendanceGoalkeeper(Attendance attendance, AttendanceHomeData data) {
    return data.usersById[attendance.userId]?.goalkeeper ?? false;
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

String _sessionTitle(DateTime scheduledAt) {
  return 'Racha de ${_weekday(scheduledAt)} — ${_twoDigits(scheduledAt.day)}/${_twoDigits(scheduledAt.month)}';
}

String _weekday(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'segunda',
    DateTime.tuesday => 'terça',
    DateTime.wednesday => 'quarta',
    DateTime.thursday => 'quinta',
    DateTime.friday => 'sexta',
    DateTime.saturday => 'sábado',
    DateTime.sunday => 'domingo',
    _ => '',
  };
}

String _time(DateTime date) {
  return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
