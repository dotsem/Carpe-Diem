import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class TaskFormDeleteHandler {
  static void confirmAndDelete({
    required BuildContext context,
    required WidgetRef ref,
    required Task? task,
  }) {
    if (task == null) return;
    final subtasks = ref
        .read(taskProvider)
        .tasks
        .where((t) => t.parentId == task.id)
        .toList();
    final message = subtasks.isEmpty
        ? 'Are you sure you want to delete this task?'
        : 'Are you sure you want to delete this task and its ${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}?';

    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Task',
        message: message,
        onConfirm: () {
          Navigator.of(ctx).pop();
          ref.read(taskProvider.notifier).deleteTask(task);
          ref.read(rightSidebarProvider.notifier).close();
        },
      ),
    );
  }
}
