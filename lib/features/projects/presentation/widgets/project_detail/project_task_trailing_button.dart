import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';

class ProjectTaskTrailingButton extends ConsumerWidget {
  final Task task;

  const ProjectTaskTrailingButton({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                final localPosition = Offset.zero;
                if (task.scheduledDate != null) {
                  showTaskCardContextMenu(context, ref, task, localPosition, renderBox);
                } else {
                  showBacklogContextMenu(context, ref, task, localPosition, renderBox);
                }
              },
            );
          },
        ),
      ],
    );
  }
}
