import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/hidden_counts_provider.dart';

class SidebarProjectsHiddenBadge extends ConsumerWidget {
  const SidebarProjectsHiddenBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final isBypassed = filterState.isBypassed && !filterState.filter.isEmpty;
    final hiddenProjects = ref.watch(hiddenProjectsCountProvider);

    if (!isBypassed && !hiddenProjects.hasHidden) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isBypassed ? theme.colorScheme.error : Colors.orange;

    final String tooltipMessage;
    final String labelText;
    final IconData iconData;

    if (isBypassed) {
      labelText = 'Bypassed';
      tooltipMessage = 'Filters are temporarily bypassed (Shift+F). Tap to re-enable.';
      iconData = Icons.filter_list_off;
    } else if (hiddenProjects.archivedHidden > 0) {
      labelText = hiddenProjects.activeHidden > 0
          ? '${hiddenProjects.activeHidden} hidden'
          : '${hiddenProjects.archivedHidden} archived hidden';
      tooltipMessage =
          '${hiddenProjects.activeHidden} active projects hidden by filter (${hiddenProjects.archivedHidden} archived)';
      iconData = Icons.visibility_off_outlined;
    } else {
      labelText = '${hiddenProjects.activeHidden} hidden';
      tooltipMessage = '${hiddenProjects.activeHidden} projects hidden by filter';
      iconData = Icons.visibility_off_outlined;
    }

    return Tooltip(
      message: tooltipMessage,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(filterProvider.notifier).toggleBypass();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warningColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 11, color: warningColor),
                const SizedBox(width: 4),
                Text(
                  labelText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: warningColor,
                    fontSize: 10,
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
