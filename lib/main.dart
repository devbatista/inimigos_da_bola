import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/auth_providers.dart';
import 'core/db/database_providers.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_providers.dart';
import 'features/attendance/presentation/controllers/attendance_providers.dart';
import 'features/attendance/presentation/controllers/guest_attendance_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/players/presentation/controllers/players_providers.dart';
import 'features/skill_ratings/presentation/controllers/skill_ratings_providers.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: InimigosDaBolaApp()));
}

class InimigosDaBolaApp extends ConsumerWidget {
  const InimigosDaBolaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider).themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthStatus>(
      authControllerProvider.select((controller) => controller.status),
      (previous, next) {
        // Ao deslogar, invalida controllers escopados ao usuário e limpa o
        // cache local. Isso evita que dados do login anterior — ou registros
        // órfãos de seeds antigos do backend — sobrevivam até a próxima sessão.
        if (previous == AuthStatus.authenticated &&
            next == AuthStatus.unauthenticated) {
          ref.invalidate(attendanceControllerProvider);
          ref.invalidate(guestAttendanceControllerProvider);
          ref.invalidate(playersControllerProvider);
          ref.invalidate(skillRatingsControllerProvider);
          unawaited(ref.read(appDatabaseProvider).clearAllUserData());
        }
      },
    );

    final status = ref.watch(
      authControllerProvider.select((controller) => controller.status),
    );

    return switch (status) {
      AuthStatus.checking => const _SplashScreen(),
      AuthStatus.authenticated => const AppShell(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
