import 'package:flutter/material.dart';

class ShortcutHintBadge extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const ShortcutHintBadge({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
