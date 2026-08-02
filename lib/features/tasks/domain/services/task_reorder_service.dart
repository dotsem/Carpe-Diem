import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';

class TaskReorderService {
  static String computeSortOrder({
    required TaskPlacement placement,
    required List<Task> activeList,
  }) {
    switch (placement) {
      case TaskPlacement.top || TaskPlacement.urgent:
        return LexoRankUtils.generateTop(activeList.firstOrNull?.sortOrder);
      case TaskPlacement.middle:
        return LexoRankUtils.generateMiddle(
          activeList.firstOrNull?.sortOrder,
          activeList.lastOrNull?.sortOrder,
        );
      default:
        return LexoRankUtils.generateBottom(activeList.lastOrNull?.sortOrder);
    }
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

      return b.createdAt.compareTo(a.createdAt);
    });

    return updatedList;
  }
}
