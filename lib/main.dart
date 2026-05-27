import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/attendance/presentation/screens/home_screen.dart';

void main() {
  runApp(const InimigosDaBolaApp());
}

class InimigosDaBolaApp extends StatelessWidget {
  const InimigosDaBolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inimigos da Bola',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
