import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF0F0F0E);
  static const leather = Color(0xFFA88C6C);
  static const chalk = Color(0xFFFAF7F2);
  static const stone = Color(0xFF5C5A56);
  static const mist = Color(0xFFE5E1DB);

  static const success = Color(0xFF5C7A4A);
  static const warning = Color(0xFFC8954E);
  static const danger = Color(0xFFA24C3B);
}

extension AppColorOpacity on Color {
  Color get muted => withValues(alpha: 0.6);
  Color get disabled => withValues(alpha: 0.38);
  Color get subtle => withValues(alpha: 0.12);
  Color get pressed => withValues(alpha: 0.16);
}
