import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/toast/toast_utils.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/delete_tag_command.dart';
import 'package:carpe_diem/features/tags/presentation/utils/update_tag_command.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionToastData {
  final IconData icon;
  final Color? primaryColor;
  final String? subtitle;

  const ActionToastData({required this.icon, this.primaryColor, this.subtitle});
}

class ActionToastHandler {
  static void handleUndoRedoStateChange(
    WidgetRef ref,
    BuildContext context,
    UndoRedoState next,
  ) {
    if (next.isProcessing) return;

    final opType = next.lastOperationType;
    if (opType == UndoRedoOperationType.none) return;

    if (opType == UndoRedoOperationType.execute && next.canUndo) {
      if (next.undoDescription == null) return;
      final cmd = next.undoStack.lastOrNull;
      final toastData = resolveExecuteToastData(
        cmd: cmd,
        filterState: ref.read(filterProvider),
        projects: ref.read(projectProvider).projects,
      );

      ToastUtils.showUndoable(
        next.undoDescription!,
        () => ref.read(undoRedoProvider.notifier).undo(),
        context: context,
        icon: toastData.icon,
        primaryColor: toastData.primaryColor,
        subtitle: toastData.subtitle,
      );
    } else if (opType == UndoRedoOperationType.redo && next.canUndo) {
      if (next.undoDescription == null) return;
      ToastUtils.showUndoable(
        'Redone: ${next.undoDescription}',
        () => ref.read(undoRedoProvider.notifier).undo(),
        context: context,
        icon: Icons.redo,
        primaryColor: AppColors.info,
      );
    } else if (opType == UndoRedoOperationType.undo) {
      if (next.redoDescription == null) return;
      ToastUtils.showSuccess(
        'Undone: ${next.redoDescription}',
        context: context,
        icon: Icons.undo,
      );
    }
  }

  static ActionToastData resolveExecuteToastData({
    required Command? cmd,
    FilterState filterState = const FilterState(),
    List<Project> projects = const [],
  }) {
    if (cmd == null) {
      return const ActionToastData(
        icon: Icons.check_circle_outline,
        primaryColor: AppColors.info,
      );
    }

    if (cmd is CompoundCommand) {
      final desc = cmd.description.toLowerCase();
      if (desc.contains('import')) {
        return const ActionToastData(
          icon: Icons.file_upload_outlined,
          primaryColor: AppColors.info,
        );
      }
      if (desc.contains('delete') && desc.contains('task')) {
        return const ActionToastData(
          icon: Icons.delete_sweep_outlined,
          primaryColor: AppColors.error,
        );
      }
      if (desc.contains('update') && desc.contains('task')) {
        return const ActionToastData(
          icon: Icons.checklist,
          primaryColor: AppColors.info,
        );
      }
    }

    final primary = _getPrimaryCommand(cmd);

    if (primary is CreateCommand<Task>) {
      final task = primary.item;
      final isHidden = isTaskHidden(
        task: task,
        filterState: filterState,
        projects: projects,
      );
      return ActionToastData(
        icon: Icons.add_task,
        primaryColor: AppColors.success,
        subtitle: isHidden ? 'Hidden by active filter' : null,
      );
    }

    if (primary is UpdateCommand<Task>) {
      final task = primary.next;
      final isHidden = isTaskHidden(
        task: task,
        filterState: filterState,
        projects: projects,
      );
      return ActionToastData(
        icon: Icons.edit_outlined,
        primaryColor: AppColors.info,
        subtitle: isHidden ? 'Hidden by active filter' : null,
      );
    }

    if (primary is DeleteCommand<Task>) {
      return const ActionToastData(
        icon: Icons.delete_outline,
        primaryColor: AppColors.error,
      );
    }

    if (primary is CreateCommand<Project>) {
      return const ActionToastData(
        icon: Icons.create_new_folder_outlined,
        primaryColor: AppColors.success,
      );
    }
    if (primary is UpdateCommand<Project>) {
      return const ActionToastData(
        icon: Icons.folder_outlined,
        primaryColor: AppColors.info,
      );
    }
    if (primary is DeleteCommand<Project>) {
      return const ActionToastData(
        icon: Icons.folder_delete_outlined,
        primaryColor: AppColors.error,
      );
    }

    if (primary is CreateCommand<Tag> || primary is CreateCommand<Label>) {
      return ActionToastData(
        icon: primary is CreateCommand<Tag> ? Icons.tag : Icons.label_outline,
        primaryColor: AppColors.success,
      );
    }

    if (primary is UpdateTagCommand || primary is UpdateCommand<Label>) {
      return ActionToastData(
        icon: primary is UpdateTagCommand ? Icons.tag : Icons.label_outline,
        primaryColor: AppColors.info,
      );
    }

    if (primary is DeleteTagCommand || primary is DeleteCommand<Label>) {
      return ActionToastData(
        icon: primary is DeleteTagCommand ? Icons.tag : Icons.label_outline,
        primaryColor: AppColors.error,
      );
    }

    return const ActionToastData(
      icon: Icons.check_circle_outline,
      primaryColor: AppColors.info,
    );
  }

  static bool isTaskHidden({
    required Task task,
    required FilterState filterState,
    required List<Project> projects,
  }) {
    if (filterState.isBypassed || filterState.filter.isEmpty) {
      return false;
    }
    final project = task.projectId != null
        ? projects.where((p) => p.id == task.projectId).firstOrNull
        : null;
    return !filterState.filter.applyToTask(task, project?.labelIds ?? const []);
  }

  // ponytail: extract root command from nested compounds
  static Command _getPrimaryCommand(Command cmd) {
    if (cmd is CompoundCommand && cmd.commands.isNotEmpty) {
      return _getPrimaryCommand(cmd.commands.first);
    }
    return cmd;
  }
}
