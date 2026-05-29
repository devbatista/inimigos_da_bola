import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/presentation/screens/guest_attendances_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/game_mode/presentation/screens/game_mode_screen.dart';
import '../../features/players/presentation/screens/players_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/skill_ratings/presentation/screens/skill_ratings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/teams/presentation/screens/teams_draw_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/auth_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = _destinations(l10n);
    final currentDestination = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(currentDestination.label)),
      body: currentDestination.screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  List<_AppDestination> _destinations(AppLocalizations l10n) {
    return [
      _AppDestination(
        label: l10n.homeMenuLabel,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: const HomeScreen(),
      ),
      _AppDestination(
        label: l10n.teamsDrawMenuLabel,
        icon: Icons.shuffle_outlined,
        selectedIcon: Icons.shuffle,
        screen: const TeamsDrawScreen(),
      ),
      _AppDestination(
        label: l10n.gameModeMenuLabel,
        icon: Icons.sports_soccer_outlined,
        selectedIcon: Icons.sports_soccer,
        screen: const GameModeScreen(),
      ),
      _AppDestination(
        label: l10n.statsMenuLabel,
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        screen: const StatsScreen(),
      ),
      _AppDestination(
        label: l10n.moreMenuLabel,
        icon: Icons.more_horiz,
        selectedIcon: Icons.more,
        screen: const _MoreScreen(),
      ),
    ];
  }
}

class _MoreScreen extends ConsumerWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: Text(l10n.guestAttendancesMenuLabel),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const GuestAttendancesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(l10n.playersMenuLabel),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const PlayersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: Text(l10n.skillRatingsMenuLabel),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SkillRatingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsMenuLabel),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logoutMenuLabel),
            onTap: () {
              ref.read(authControllerProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
