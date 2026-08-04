import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/shell/undo_redo_panel.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/edit_project_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RightSidebarPanelBody extends ConsumerWidget {
  final RightSidebarPanel panel;

  const RightSidebarPanelBody({super.key, required this.panel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (panel) {
      AddTaskPanel(:final initialDate, :final initialProjectId, :final initialParentId) => AddTaskDialog(
        initialDate: initialDate,
        initialProjectId: initialProjectId,
        initialParentId: initialParentId,
      ),
      EditTaskPanel(:final taskId) => Consumer(
        builder: (context, ref, child) {
          final task = ref.watch(taskProvider).getById(taskId);
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }
          return EditTaskDialog(task: task);
        },
      ),
      EditProjectPanel(:final projectId) => Consumer(
        builder: (context, ref, child) {
          final project = ref.watch(projectProvider).getById(projectId);
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }
          return EditProjectDialog(project: project);
        },
      ),
      ActionHistoryPanel() => const ActionHistoryDialog(),
    };
  }
}
