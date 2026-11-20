import 'package:flutter/material.dart';

class ContextMenuItemTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final Color? color;

  const ContextMenuItemTile({
    required this.leading,
    required this.title,
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(
          data: IconThemeData(
            size: 20,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: leading,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
