import 'package:flutter/material.dart';
import 'package:carpe_diem/features/common/presentation/widgets/shortcut_hint_badge.dart';

class CommandPaletteFooter extends StatelessWidget {
  final int count;

  const CommandPaletteFooter({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const ShortcutHintBadge(label: '↑↓'),
          const SizedBox(width: 6),
          Text(
            'Navigate',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 14),
          const ShortcutHintBadge(label: '↵'),
          const SizedBox(width: 6),
          Text(
            'Select',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 14),
          const ShortcutHintBadge(label: 'ESC'),
          const SizedBox(width: 6),
          Text(
            'Close',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          Text(
            '$count command${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
