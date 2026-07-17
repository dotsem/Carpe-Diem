import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

class BlockerIndicator extends ConsumerWidget {
  final String blockerId;
  final String blockerTitle;
  final String blockedTaskId;

  const BlockerIndicator({super.key, required this.blockerId, required this.blockerTitle, required this.blockedTaskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHashtags = ref.watch(settingsProvider).showHashtagInTitle;
    final title = showHashtags ? blockerTitle : TagParser.hideHashtagSymbols(blockerTitle);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: 'Blocked by: $title',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Task is blocked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
