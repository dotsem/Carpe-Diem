import 'package:flutter/material.dart';

class HorizontalTab extends StatelessWidget {
  final Widget? icon;
  final String label;
  final int? count;
  final Color? accentColor;
  final bool showIconOnly;
  final double spacing;
  const HorizontalTab({
    required this.label,
    super.key,
    this.icon,
    this.count,
    this.accentColor,
    this.spacing = 4.0,
    this.showIconOnly = false,
  }) : assert(
         showIconOnly || icon != null,
         'Icon must be provided if showIconOnly is true',
       );

  @override
  Widget build(BuildContext context) {
    return Tab(
      icon: showIconOnly ? icon : null,
      child: showIconOnly
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: spacing,
              children: [
                ?icon,
                Text(label),
                if (count != null)
                  _TabCountBadge(count: count!, accentColor: accentColor),
              ],
            ),
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  final int count;
  final Color? accentColor;

  const _TabCountBadge({required this.count, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = accentColor != null
        ? accentColor!.withAlpha(30)
        : theme.colorScheme.surfaceContainerHighest;
    final fg = accentColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
