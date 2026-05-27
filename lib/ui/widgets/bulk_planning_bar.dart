import 'dart:ui';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BulkPlanningBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;
  final VoidCallback onBulkEdit;
  final VoidCallback onBulkDelete;

  const BulkPlanningBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onBulkEdit,
    required this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Clear selection',
                    onPressed: onClearSelection,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedCount == 1 ? '1 task selected' : '$selectedCount tasks selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(height: 24, width: 1, color: theme.colorScheme.outlineVariant),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Today',
                    tooltip: 'Schedule for today',
                    color: AppColors.info,
                    onPressed: onScheduleToday,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.next_plan_outlined,
                    label: 'Tomorrow',
                    tooltip: 'Schedule for tomorrow',
                    color: AppColors.info,
                    onPressed: onScheduleTomorrow,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    tooltip: selectedCount == 1 ? 'Edit Task' : 'Bulk Edit',
                    color: theme.colorScheme.onSurface,
                    onPressed: onBulkEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    tooltip: selectedCount == 1 ? 'Delete Task' : 'Bulk Delete',
                    color: AppColors.error,
                    onPressed: onBulkDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: enabled ? color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        label: Text(
          label,
          style: TextStyle(
            color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
