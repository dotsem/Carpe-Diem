import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SubtaskProgressChip extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const SubtaskProgressChip({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isAllDone = completedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isAllDone
            ? AppColors.success.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAllDone ? Icons.check_circle_outline : Icons.checklist_rounded,
            size: 12,
            color: isAllDone
                ? AppColors.success
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAllDone
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
