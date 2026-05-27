import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
  }) : _variant = _AppButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: Text(label),
      ),
      _AppButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    };
  }
}

enum _AppButtonVariant { primary, secondary }
