import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/attendance/presentation/screens/home_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  runApp(const InimigosDaBolaApp());
}

class InimigosDaBolaApp extends StatelessWidget {
  const InimigosDaBolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
