import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagChip extends ConsumerWidget {
  final Tag tag;
  final double verticalPadding;

  const TagChip({super.key, required this.tag, this.verticalPadding = 2});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayColor = colorScheme.onSurfaceVariant;
    final tagIcons = ref.watch(tagIconProvider);
    final icon = tagIcons[tag.name.trim().toLowerCase()] ?? Icons.tag;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: TextStyle(color: displayColor, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
