import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';

class KanbanColumnHeader extends StatelessWidget {
  final String title;
  final Color titleColor;
  final int count;
  final bool isNarrow;
  final VoidCallback? onToggle;

  const KanbanColumnHeader({
    super.key,
    required this.title,
    required this.titleColor,
    required this.count,
    this.isNarrow = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = TaskReorderScope.of(context);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        scope?.onHoverSlot(details.data, 0);
        return true;
      },
      onLeave: (_) => scope?.onLeaveSlot(),
      onAcceptWithDetails: (details) => scope?.drop(details.data, 0),
      builder: (context, _, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SmallChip(
              borderRadius: 10,
              color: titleColor.withValues(alpha: 0.15),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            if (onToggle != null && isNarrow)
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 16),
                onPressed: onToggle,
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
