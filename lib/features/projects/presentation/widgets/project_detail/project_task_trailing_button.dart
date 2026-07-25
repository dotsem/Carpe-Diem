import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';

class ProjectTaskTrailingButton extends ConsumerWidget {
  final Task task;
  final List<Task> tasks;

  const ProjectTaskTrailingButton({super.key, required this.task, required this.tasks});

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
                showTaskCardContextMenu(context, ref, task, tasks, localPosition, renderBox);
              },
            );
          },
        ),
      ],
    );
  }
}
