import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

class HiddenProjectsCount {
  final int activeHidden;
  final int archivedHidden;

  const HiddenProjectsCount({this.activeHidden = 0, this.archivedHidden = 0});

  int get totalHidden => activeHidden + archivedHidden;
  bool get hasHidden => totalHidden > 0;
}

final hiddenProjectsCountProvider = Provider<HiddenProjectsCount>((ref) {
  final filterState = ref.watch(filterProvider);
  if (filterState.isBypassed) {
    return const HiddenProjectsCount();
  }

  final filter = filterState.filter.limitTo(projects: false);
  if (filter.isEmpty) {
    return const HiddenProjectsCount();
  }

  final projectState = ref.watch(projectProvider);
  final projects = projectState.projects;

  int activeHidden = 0;
  int archivedHidden = 0;

  for (final project in projects) {
    if (!filter.applyToProject(project)) {
      if (project.isActive) {
        activeHidden++;
      } else {
        archivedHidden++;
      }
    }
  }

  return HiddenProjectsCount(
    activeHidden: activeHidden,
    archivedHidden: archivedHidden,
  );
});

final hiddenUnscheduledTasksCountProvider = Provider<int>((ref) {
  final filterState = ref.watch(filterProvider);
  if (filterState.isBypassed) return 0;
  final filter = filterState.filter;
  if (filter.isEmpty) return 0;

  final taskState = ref.watch(taskProvider);
  final projectState = ref.watch(projectProvider);
  final unscheduled = taskState.unscheduledTasks;

  int hidden = 0;
  for (final task in unscheduled) {
    final project = task.projectId != null
        ? projectState.getById(task.projectId!)
        : null;
    if (!filter.applyToTask(task, project?.labelIds ?? [])) {
      hidden++;
    }
  }
  return hidden;
});

final hiddenTodayTasksCountProvider = Provider<int>((ref) {
  final filterState = ref.watch(filterProvider);
  if (filterState.isBypassed) return 0;
  final filter = filterState.filter;
  if (filter.isEmpty) return 0;

  final taskState = ref.watch(taskProvider);
  final projectState = ref.watch(projectProvider);
  final todayTasks = taskState.tasks;

  int hidden = 0;
  for (final task in todayTasks) {
    final project = task.projectId != null
        ? projectState.getById(task.projectId!)
        : null;
    if (!filter.applyToTask(task, project?.labelIds ?? [])) {
      hidden++;
    }
  }
  return hidden;
});
