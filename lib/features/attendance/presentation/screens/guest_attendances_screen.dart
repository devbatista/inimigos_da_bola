import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/guest_attendance_providers.dart';

class GuestAttendancesScreen extends ConsumerWidget {
  const GuestAttendancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(guestAttendanceControllerProvider);
    final data = controller.data;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmações avulsas')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(guestAttendanceControllerProvider).load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppButton.primary(
                label: controller.submitting
                    ? 'Atualizando...'
                    : 'Adicionar avulso',
                onPressed: controller.submitting || data == null
                    ? null
                    : () => _showCreateDialog(context, ref),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _InlineError(message: controller.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.md),
              if (controller.loading && data == null)
                const AppCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (data == null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _InlineError(
                        message:
                            'Não foi possível carregar as presenças avulsas.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton.secondary(
                        label: 'Tentar novamente',
                        onPressed: () =>
                            ref.read(guestAttendanceControllerProvider).load(),
                      ),
                    ],
                  ),
                )
              else
                _GuestsList(
                  guests: data.guests,
                  submitting: controller.submitting,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final guestName = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateGuestDialog(),
    );

    if (guestName == null || guestName.isEmpty) {
      return;
    }

    await ref.read(guestAttendanceControllerProvider).create(guestName);
  }
}

class _CreateGuestDialog extends StatefulWidget {
  const _CreateGuestDialog();

  @override
  State<_CreateGuestDialog> createState() => _CreateGuestDialogState();
}

class _CreateGuestDialogState extends State<_CreateGuestDialog> {
  final _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final guestName = _nameController.text.trim();
    if (guestName.isEmpty) {
      setState(() => _errorText = 'Informe o nome do avulso.');
      return;
    }

    Navigator.of(context).pop(guestName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar avulso'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Nome',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _GuestsList extends ConsumerWidget {
  const _GuestsList({required this.guests, required this.submitting});

  final List<Attendance> guests;
  final bool submitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (guests.isEmpty) {
      return const AppCard(child: Text('Nenhum avulso confirmado.'));
    }

    return AppCard(
      child: Column(
        children: [
          for (final guest in guests) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(guest.guestName ?? 'Avulso'),
              subtitle: Text(_subtitle(guest)),
              trailing: IconButton(
                tooltip: 'Remover avulso',
                icon: const Icon(Icons.delete_outline),
                onPressed: submitting
                    ? null
                    : () => ref
                          .read(guestAttendanceControllerProvider)
                          .delete(guest.id),
              ),
            ),
            if (guest != guests.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  String _subtitle(Attendance guest) {
    if (guest.status == 'confirmed' && guest.waitlistPosition != null) {
      return 'Lista de espera #${guest.waitlistPosition}';
    }

    return switch (guest.status) {
      'confirmed' => 'Confirmado',
      'declined' => 'Não vai',
      _ => 'Pendente',
    };
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
