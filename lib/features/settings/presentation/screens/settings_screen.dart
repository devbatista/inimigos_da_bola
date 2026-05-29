import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_providers.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/settings_repository.dart';
import '../controllers/settings_controller.dart';
import '../controllers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncDao = ref.watch(syncDaoProvider);
    final settingsController = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            _ProfileCard(controller: settingsController),
            const SizedBox(height: AppSpacing.md),
            const _AppearanceCard(),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<List<SyncQueueData>>(
              stream: syncDao.watchPendingMutations(),
              builder: (context, queueSnapshot) {
                return StreamBuilder<List<SyncStateData>>(
                  stream: syncDao.watchSyncStates(),
                  builder: (context, stateSnapshot) {
                    return _SyncStatusCard(
                      pendingMutations: queueSnapshot.data ?? const [],
                      syncStates: stateSnapshot.data ?? const [],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const _CacheInfoCard(),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout),
                title: const Text('Sair da conta'),
                subtitle: const Text('Remove a sessão salva neste aparelho.'),
                onTap: () {
                  ref.read(authControllerProvider).signOut();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final errorMessage = controller.errorMessage;
    final successMessage = controller.successMessage;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Meu perfil',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (controller.loading && profile == null)
            const Center(child: CircularProgressIndicator())
          else if (profile == null)
            const Text('Perfil ainda não carregado.')
          else ...[
            _MetricRow(label: 'Nome', value: profile.name),
            _MetricRow(
              label: 'Telefone',
              value: profile.phone ?? 'Não informado',
            ),
            _MetricRow(
              label: 'Goleiro',
              value: profile.goalkeeper ? 'Sim' : 'Não',
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: controller.saving
                  ? null
                  : () => _showEditProfileDialog(context, controller, profile),
              icon: const Icon(Icons.edit_outlined),
              label: Text(controller.saving ? 'Salvando...' : 'Editar perfil'),
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (successMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              successMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    SettingsController controller,
    User profile,
  ) async {
    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    var goalkeeper = profile.goalkeeper;
    String? nameError;

    final update = await showDialog<SettingsProfileUpdate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
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
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sou goleiro'),
                    value: goalkeeper,
                    onChanged: (value) => setState(() => goalkeeper = value),
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
                    final phone = phoneController.text.trim();
                    if (name.isEmpty) {
                      setState(() => nameError = 'Informe o nome.');
                      return;
                    }

                    Navigator.of(context).pop(
                      SettingsProfileUpdate(
                        name: name,
                        phone: phone.isEmpty ? null : phone,
                        goalkeeper: goalkeeper,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();

    if (update != null) {
      await controller.updateProfile(update);
    }
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeController = ref.watch(themeModeControllerProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Aparência',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
            ],
            selected: {themeModeController.themeMode},
            onSelectionChanged: (selection) {
              themeModeController.setThemeMode(selection.single);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'As cores seguem os tokens do design system; aqui você escolhe o modo visual do app.',
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.pendingMutations,
    required this.syncStates,
  });

  final List<SyncQueueData> pendingMutations;
  final List<SyncStateData> syncStates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oldestMutation = pendingMutations.isEmpty
        ? null
        : pendingMutations.first.createdAt;
    final lastError = pendingMutations
        .map((mutation) => mutation.lastError)
        .whereType<String>()
        .where((error) => error.isNotEmpty)
        .firstOrNull;
    final lastSync = syncStates.isEmpty
        ? null
        : syncStates
              .map((state) => state.lastSyncedAt)
              .reduce(
                (first, second) => first.isAfter(second) ? first : second,
              );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Status de sincronização',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            label: 'Mutações pendentes',
            value: '${pendingMutations.length}',
          ),
          _MetricRow(
            label: 'Mais antiga',
            value: oldestMutation == null
                ? 'Nenhuma'
                : _formatRelativeAge(oldestMutation),
          ),
          _MetricRow(
            label: 'Último sync',
            value: lastSync == null
                ? 'Ainda não registrado'
                : _formatDate(lastSync),
          ),
          _MetricRow(label: 'Última falha', value: lastError ?? 'Nenhuma'),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: pendingMutations.isEmpty
                  ? AppColors.success.subtle
                  : AppColors.warning.subtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                pendingMutations.isEmpty
                    ? 'Tudo que está no aparelho já saiu da fila local.'
                    : 'Há alterações salvas no aparelho aguardando sync.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CacheInfoCard extends StatelessWidget {
  const _CacheInfoCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dados locais',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'O app lê do cache local primeiro. Presença exige internet, mas sorteio, modo jogo e lançamento de stats continuam utilizáveis na quadra.',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  return DateFormat('dd/MM HH:mm').format(dateTime);
}

String _formatRelativeAge(DateTime dateTime) {
  final age = DateTime.now().difference(dateTime);
  if (age.inMinutes < 1) {
    return 'Agora';
  }
  if (age.inHours < 1) {
    return '${age.inMinutes} min';
  }
  if (age.inDays < 1) {
    return '${age.inHours} h';
  }
  return '${age.inDays} d';
}
