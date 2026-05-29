import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/attendance_chip.dart';
import '../../../../core/widgets/player_tile.dart';
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
    final confirmedCount = data.mainConfirmed.length;
    final maxPlayers = data.session.maxPlayers;
    final waitlistCount = data.waitlisted.length;
    final progress = maxPlayers == 0
        ? 0.0
        : (confirmedCount / maxPlayers).clamp(0.0, 1.0);
    final currentAttendance = data.attendances
        .where((attendance) => attendance.userId == data.currentUser.id)
        .firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sessionTitle(scheduledAt),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _LocationAction(
                            label: 'Arena X',
                            onTap: () => _showMapOptions(context, 'Arena X'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _time(scheduledAt),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _MyStatusChip(attendance: currentAttendance),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppSpacing.sm,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.confirmedCounter(confirmedCount, maxPlayers),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DashboardMetric(
                  label: 'Confirmados',
                  value: '$confirmedCount',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DashboardMetric(
                  label: 'Na espera',
                  value: '$waitlistCount',
                  icon: Icons.hourglass_top_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DashboardMetric(
                  label: 'Pendentes',
                  value: '${data.pending.length}',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.leather,
                ),
              ),
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
          const SizedBox(height: AppSpacing.lg),
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

  Future<void> _showMapOptions(BuildContext context, String location) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Abrir no Google Maps'),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchMap(context, _googleMapsUri(location));
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation_outlined),
                title: const Text('Abrir no Waze'),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchMap(context, _wazeUri(location));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchMap(BuildContext context, Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
      );
    }
  }
}

class _LocationAction extends StatelessWidget {
  const _LocationAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyStatusChip extends StatelessWidget {
  const _MyStatusChip({required this.attendance});

  final Attendance? attendance;

  @override
  Widget build(BuildContext context) {
    final status = attendance?.status;
    final (label, chipStatus) = switch (status) {
      'confirmed' => ('Vou', AttendanceChipStatus.confirmed),
      'declined' => ('Não vou', AttendanceChipStatus.declined),
      _ => ('Pendente', AttendanceChipStatus.pending),
    };

    return AttendanceChip(label: label, status: chipStatus);
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
    final isPrimary = expanded;

    return AppCard(
      padding: AppSpacing.sm,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
        leading: Icon(
          isPrimary ? Icons.groups_outlined : Icons.list_alt_outlined,
          color: isPrimary ? AppColors.success : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
            _SectionCountBadge(
              count: attendances.length,
              highlighted: isPrimary,
            ),
          ],
        ),
        children: [
          if (attendances.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nenhum jogador.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            )
          else
            for (final attendance in attendances) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: PlayerTile(
                  name: _attendanceName(attendance, data),
                  label: _attendanceLabel(attendance, data, context),
                  goalkeeper: _attendanceGoalkeeper(attendance, data),
                  guest: attendance.kind == 'guest',
                ),
              ),
              if (attendance != attendances.last)
                const Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.xxl,
                    right: AppSpacing.sm,
                  ),
                  child: Divider(height: AppSpacing.lg),
                ),
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

class _SectionCountBadge extends StatelessWidget {
  const _SectionCountBadge({required this.count, required this.highlighted});

  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.success : AppColors.stone;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
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

Uri _googleMapsUri(String location) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': location,
  });
}

Uri _wazeUri(String location) {
  return Uri.https('waze.com', '/ul', {'q': location, 'navigate': 'yes'});
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
