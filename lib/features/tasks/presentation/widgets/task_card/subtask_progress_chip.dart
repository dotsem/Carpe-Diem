import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SubtaskProgressChip extends StatelessWidget {
  final int completedCount;
  final int plannedCount;
  final int totalCount;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const SubtaskProgressChip({
    super.key,
    required this.completedCount,
    required this.plannedCount,
    required this.totalCount,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final isAllDone = completedCount == totalCount && totalCount > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isAllDone
        ? AppColors.success
        : colorScheme.onSurfaceVariant;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isAllDone
            ? AppColors.success.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAllDone ? Icons.check_circle_outline : Icons.checklist_rounded,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          if (plannedCount > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              '$plannedCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
          if (onToggleCollapse != null) ...[
            const SizedBox(width: 2),
            Icon(
              isCollapsed ? Icons.chevron_right : Icons.expand_more,
              size: 14,
              color: textColor,
            ),
          ],
        ],
      ),
    );

    if (onToggleCollapse == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleCollapse,
      child: child,
    );
  }
}
