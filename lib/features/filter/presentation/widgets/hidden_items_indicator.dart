import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';

class HiddenItemsIndicator extends ConsumerWidget {
  final int count;
  final String itemType;
  final int archivedCount;
  final VoidCallback? onTap;

  const HiddenItemsIndicator({
    super.key,
    required this.count,
    required this.itemType,
    this.archivedCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final isBypassed = filterState.isBypassed && !filterState.filter.isEmpty;

    if (!isBypassed && count <= 0 && archivedCount <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isBypassed ? theme.colorScheme.error : Colors.orange;

    final String tooltipMessage;
    final String labelText;
    final IconData iconData;

    if (isBypassed) {
      labelText = 'Filter Passthrough';
      tooltipMessage =
          'Filters are temporarily bypassed (Shift+F). Tap to re-enable.';
      iconData = Icons.filter_list_off;
    } else if (archivedCount > 0) {
      labelText = count > 0
          ? '$count $itemType hidden'
          : '$archivedCount archived $itemType hidden';
      tooltipMessage =
          '$count active $itemType hidden by filter ($archivedCount archived)';
      iconData = Icons.visibility_off_outlined;
    } else {
      labelText = '$count $itemType hidden';
      tooltipMessage = '$count $itemType hidden by filter';
      iconData = Icons.visibility_off_outlined;
    }

    return Tooltip(
      message: tooltipMessage,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              onTap ??
              () {
                ref.read(filterProvider.notifier).toggleBypass();
              },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: warningColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 14, color: warningColor),
                const SizedBox(width: 6),
                Text(
                  labelText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
