import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';

class TaskReorderService {
  static String computeSortOrder({
    required TaskPlacement placement,
    required List<Task> activeList,
  }) {
    if (activeList.isEmpty) {
      return LexoRankUtils.defaultRank;
    }

    switch (placement) {
      case TaskPlacement.top || TaskPlacement.urgent:
        final topRank = TaskReorderUtils.getEffectiveRank(activeList, 0);
        return LexoRankUtils.generateTop(topRank);

      case TaskPlacement.middle:
        if (activeList.length == 1) {
          final singleRank = TaskReorderUtils.getEffectiveRank(activeList, 0);
          return LexoRankUtils.generateBetween(null, singleRank);
        }
        final midIndex = activeList.length ~/ 2;
        final prevRank = TaskReorderUtils.getEffectiveRank(
          activeList,
          midIndex - 1,
        );
        final nextRank = TaskReorderUtils.getEffectiveRank(
          activeList,
          midIndex,
        );
        return LexoRankUtils.generateBetween(prevRank, nextRank);

      default:
        final bottomRank = TaskReorderUtils.getEffectiveRank(
          activeList,
          activeList.length - 1,
        );
        return LexoRankUtils.generateBottom(bottomRank);
    }
  }

  static TaskState applyOptimisticTask({
    required TaskState state,
    required Task task,
    required SettingsState settings,
  }) {
    return state.copyWith(
      tasks: optimisticallyReorder(
        currentList: state.tasks,
        updatedTask: task,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      overdueTasks: optimisticallyReorder(
        currentList: state.overdueTasks,
        updatedTask: task,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      unscheduledTasks: optimisticallyReorder(
        currentList: state.unscheduledTasks,
        updatedTask: task,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
    );
  }

  static TaskState applyBulkOptimisticReorder({
    required TaskState state,
    required Map<String, String> updates,
    required SettingsState settings,
  }) {
    return state.copyWith(
      tasks: applyBulkOptimisticReorderList(
        list: state.tasks,
        updates: updates,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      overdueTasks: applyBulkOptimisticReorderList(
        list: state.overdueTasks,
        updates: updates,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      unscheduledTasks: applyBulkOptimisticReorderList(
        list: state.unscheduledTasks,
        updates: updates,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
    );
  }

  static List<Task> optimisticallyReorder({
    required List<Task> currentList,
    required Task updatedTask,
    required bool prioritizeOverdue,
    required bool prioritizeDeadlines,
  }) {
    if (!currentList.any((t) => t.id == updatedTask.id)) return currentList;

    final updatedList = currentList
        .map((t) => t.id == updatedTask.id ? updatedTask : t)
        .toList();

    updatedList.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;

      if (prioritizeOverdue) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
      }

      final deadlineComp = () {
        if (a.deadline == b.deadline) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      }();

      if (prioritizeDeadlines && deadlineComp != 0) {
        return deadlineComp;
      }

      final aSort = a.sortOrder.isEmpty ? '~' : a.sortOrder;
      final bSort = b.sortOrder.isEmpty ? '~' : b.sortOrder;
      final sortComp = aSort.compareTo(bSort);
      if (sortComp != 0) return sortComp;

      final createdComp = b.createdAt.compareTo(a.createdAt);
      if (createdComp != 0) return createdComp;

      return deadlineComp;
    });

    return updatedList;
  }

  static Future<List<Task>> getRelevantTasksList({
    required ITaskRepository repo,
    required String? parentId,
    required String? projectId,
    required DateTime? scheduledDate,
    required bool prioritizeDeadlines,
    required bool prioritizeOverdue,
  }) async {
    if (parentId != null) {
      return await repo.getByParent(parentId);
    }
    if (projectId != null && scheduledDate == null) {
      return await repo.getByProjectUnscheduled(
        projectId,
        prioritizeDeadlines: prioritizeDeadlines,
        prioritizeOverdue: prioritizeOverdue,
      );
    }
    if (scheduledDate == null) {
      return await repo.getUnscheduled(
        prioritizeDeadlines: prioritizeDeadlines,
        prioritizeOverdue: prioritizeOverdue,
      );
    }
    return await repo.getByDate(
      scheduledDate,
      prioritizeDeadlines: prioritizeDeadlines,
      prioritizeOverdue: prioritizeOverdue,
    );
  }

  static Command buildReorderCommand({
    required ITaskRepository repo,
    required Task previous,
    required Task next,
  }) {
    return UpdateCommand(
      repo: repo,
      previous: previous,
      next: next,
      displayName: next.title,
      customDescription: 'Reorder ${repo.repositoryName}: "${next.title}"',
    );
  }

  static Future<Command?> buildBulkReorderCommand({
    required ITaskRepository repo,
    required Map<String, String> updates,
  }) async {
    final commands = <Command>[];
    for (final entry in updates.entries) {
      final oldTask = await repo.getById(entry.key);
      if (oldTask != null) {
        final updated = oldTask.copyWith(sortOrder: entry.value);
        commands.add(
          UpdateCommand(
            repo: repo,
            previous: oldTask,
            next: updated,
            displayName: oldTask.title,
            customDescription:
                'Reorder ${repo.repositoryName}: "${oldTask.title}"',
          ),
        );
      }
    }
    if (commands.isEmpty) return null;
    if (commands.length == 1) return commands.first;
    return CompoundCommand(commands, 'Reorder ${commands.length} tasks');
  }

  static List<Task> applyBulkOptimisticReorderList({
    required List<Task> list,
    required Map<String, String> updates,
    required bool prioritizeOverdue,
    required bool prioritizeDeadlines,
  }) {
    var current = List<Task>.from(list);
    for (final entry in updates.entries) {
      final idx = current.indexWhere((t) => t.id == entry.key);
      if (idx != -1) {
        final updated = current[idx].copyWith(sortOrder: entry.value);
        current = optimisticallyReorder(
          currentList: current,
          updatedTask: updated,
          prioritizeOverdue: prioritizeOverdue,
          prioritizeDeadlines: prioritizeDeadlines,
        );
      }
    }
    return current;
  }
}
