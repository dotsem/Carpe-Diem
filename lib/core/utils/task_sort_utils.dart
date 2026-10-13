import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskSortUtils {
  static void sortTasks(
    List<Task> tasks,
    SettingsState settings, {
    bool isPlanView = false,
  }) {
    tasks.sort((a, b) => compareTasks(a, b, settings, isPlanView: isPlanView));
  }

  static int compareTasks(
    Task a,
    Task b,
    SettingsState settings, {
    bool isPlanView = false,
  }) {
    if (a.isUrgent && !b.isUrgent) return -1;
    if (!a.isUrgent && b.isUrgent) return 1;

    final deadlineComp = () {
      if (a.deadline == b.deadline) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    }();

    if (!isPlanView) {
      if (settings.prioritizeOverdue) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
      }
      if (settings.prioritizeDeadlines && deadlineComp != 0) {
        return deadlineComp;
      }
    }

    final String aSortOrder;
    final String bSortOrder;

    if (isPlanView) {
      aSortOrder = (a.planSortOrder != null && a.planSortOrder!.isNotEmpty)
          ? a.planSortOrder!
          : a.sortOrder;
      bSortOrder = (b.planSortOrder != null && b.planSortOrder!.isNotEmpty)
          ? b.planSortOrder!
          : b.sortOrder;
    } else {
      aSortOrder = a.sortOrder;
      bSortOrder = b.sortOrder;
    }

    final aSort = aSortOrder.isEmpty ? '~' : aSortOrder;
    final bSort = bSortOrder.isEmpty ? '~' : bSortOrder;
    final sortComp = aSort.compareTo(bSort);
    if (sortComp != 0) return sortComp;

    final createdComp = b.createdAt.compareTo(a.createdAt);
    if (createdComp != 0) return createdComp;

    return deadlineComp;
  }
}
