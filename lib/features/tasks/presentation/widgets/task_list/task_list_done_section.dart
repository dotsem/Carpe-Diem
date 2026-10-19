import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_components.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';

class TaskListDoneSection extends StatelessWidget {
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const TaskListDoneSection({
    super.key,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final scope = TaskReorderScope.of(context);

    final header = TaskListSectionHeader(
      title: 'Done',
      color: color,
      amount: count,
      onTap: onToggle,
      trailing: AnimatedRotation(
        duration: const Duration(milliseconds: 200),
        turns: isExpanded ? 0.5 : 0,
        child: Icon(Icons.expand_more, color: color, size: 20),
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        header,
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Column(children: children)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );

    if (!isExpanded && scope != null) {
      return DragTarget<Task>(
        onWillAcceptWithDetails: (details) {
          scope.onHoverSlot(details.data, scope.nodes.length);
          return true;
        },
        onLeave: (_) => scope.onLeaveSlot(),
        onAcceptWithDetails: (details) {
          scope.drop(details.data, scope.nodes.length);
        },
        builder: (context, _, _) => column,
      );
    }

    return column;
  }
}
