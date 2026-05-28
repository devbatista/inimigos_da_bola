import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../data/players_repository.dart';
import '../controllers/players_providers.dart';

enum _PlayerTypeFilter { all, monthly, casual }

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  _PlayerTypeFilter _typeFilter = _PlayerTypeFilter.all;
  var _goalkeepersOnly = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playersControllerProvider);
    final players = _filteredPlayers(controller.players);

    return Scaffold(
      appBar: AppBar(title: const Text('Jogadores')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(playersControllerProvider).load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppButton.primary(
                label: controller.submitting
                    ? 'Atualizando...'
                    : 'Convidar novo jogador',
                onPressed: controller.submitting
                    ? null
                    : () => _showInviteDialog(context),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _InlineError(message: controller.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.md),
              _FiltersCard(
                typeFilter: _typeFilter,
                goalkeepersOnly: _goalkeepersOnly,
                onTypeChanged: (value) => setState(() => _typeFilter = value),
                onGoalkeepersChanged: (value) =>
                    setState(() => _goalkeepersOnly = value),
              ),
              const SizedBox(height: AppSpacing.md),
              if (controller.loading && controller.players.isEmpty)
                const AppCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (players.isEmpty)
                const AppCard(child: Text('Nenhum jogador encontrado.'))
              else
                _PlayersList(
                  players: players,
                  submitting: controller.submitting,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<User> _filteredPlayers(List<User> players) {
    return players.where((player) {
      final matchesType = switch (_typeFilter) {
        _PlayerTypeFilter.all => true,
        _PlayerTypeFilter.monthly => player.playerType == 'monthly',
        _PlayerTypeFilter.casual => player.playerType == 'casual',
      };

      return matchesType && (!_goalkeepersOnly || player.goalkeeper);
    }).toList()..sort((first, second) => first.name.compareTo(second.name));
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? nameError;
    String? emailError;

    final invite = await showDialog<_InviteInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Convidar jogador'),
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
                    controller: emailController,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: emailError,
                    ),
                    onChanged: (_) {
                      if (emailError != null) {
                        setState(() => emailError = null);
                      }
                    },
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
                    final email = emailController.text.trim();
                    setState(() {
                      nameError = name.isEmpty ? 'Informe o nome.' : null;
                      emailError = email.isEmpty || !email.contains('@')
                          ? 'Informe um email válido.'
                          : null;
                    });

                    if (nameError == null && emailError == null) {
                      Navigator.of(
                        context,
                      ).pop(_InviteInput(name: name, email: email));
                    }
                  },
                  child: const Text('Convidar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();

    if (invite == null) {
      return;
    }

    await ref
        .read(playersControllerProvider)
        .invite(email: invite.email, name: invite.name);
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.typeFilter,
    required this.goalkeepersOnly,
    required this.onTypeChanged,
    required this.onGoalkeepersChanged,
  });

  final _PlayerTypeFilter typeFilter;
  final bool goalkeepersOnly;
  final ValueChanged<_PlayerTypeFilter> onTypeChanged;
  final ValueChanged<bool> onGoalkeepersChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_PlayerTypeFilter>(
            segments: const [
              ButtonSegment(value: _PlayerTypeFilter.all, label: Text('Todos')),
              ButtonSegment(
                value: _PlayerTypeFilter.monthly,
                label: Text('Mensalistas'),
              ),
              ButtonSegment(
                value: _PlayerTypeFilter.casual,
                label: Text('Avulsos'),
              ),
            ],
            selected: {typeFilter},
            onSelectionChanged: (selection) {
              onTypeChanged(selection.single);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Somente goleiros'),
            value: goalkeepersOnly,
            onChanged: onGoalkeepersChanged,
          ),
        ],
      ),
    );
  }
}

class _PlayersList extends ConsumerWidget {
  const _PlayersList({required this.players, required this.submitting});

  final List<User> players;
  final bool submitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        children: [
          for (final player in players) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: PlayerTile(
                name: player.name,
                label: player.playerType == 'monthly' ? 'Mensalista' : 'Avulso',
                goalkeeper: player.goalkeeper,
              ),
              trailing: IconButton(
                tooltip: 'Ações do jogador',
                icon: const Icon(Icons.more_horiz),
                onPressed: submitting
                    ? null
                    : () => _showActions(context, ref, player),
              ),
            ),
            if (player != players.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    User player,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar dados'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditDialog(context, ref, player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(
                  player.playerType == 'monthly'
                      ? 'Mudar para avulso'
                      : 'Mudar para mensalista',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(playersControllerProvider)
                      .update(
                        player,
                        PlayerUpdate(
                          name: player.name,
                          phone: player.phone,
                          playerType: player.playerType == 'monthly'
                              ? 'casual'
                              : 'monthly',
                          goalkeeper: player.goalkeeper,
                        ),
                      );
                },
              ),
              ListTile(
                leading: Icon(
                  player.goalkeeper
                      ? Icons.sports_soccer_outlined
                      : Icons.sports_soccer,
                ),
                title: Text(
                  player.goalkeeper ? 'Remover goleiro' : 'Marcar como goleiro',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(playersControllerProvider)
                      .update(
                        player,
                        PlayerUpdate(
                          name: player.name,
                          phone: player.phone,
                          playerType: player.playerType,
                          goalkeeper: !player.goalkeeper,
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover jogador'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(playersControllerProvider).softDelete(player);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    User player,
  ) async {
    final nameController = TextEditingController(text: player.name);
    final phoneController = TextEditingController(text: player.phone ?? '');
    String? nameError;

    final update = await showDialog<PlayerUpdate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar jogador'),
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
                    setState(() {
                      nameError = name.isEmpty ? 'Informe o nome.' : null;
                    });

                    if (nameError == null) {
                      Navigator.of(context).pop(
                        PlayerUpdate(
                          name: name,
                          phone: phone.isEmpty ? null : phone,
                          playerType: player.playerType,
                          goalkeeper: player.goalkeeper,
                        ),
                      );
                    }
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

    if (update == null) {
      return;
    }

    await ref.read(playersControllerProvider).update(player, update);
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

class _InviteInput {
  const _InviteInput({required this.name, required this.email});

  final String name;
  final String email;
}
