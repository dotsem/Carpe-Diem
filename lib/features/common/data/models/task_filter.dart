import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskFilter {
  final Set<Priority> priorities;
  final Set<String> projectIds;
  final Set<String> labelIds;

  const TaskFilter({this.priorities = const {}, this.projectIds = const {}, this.labelIds = const {}});

  bool get isEmpty => priorities.isEmpty && projectIds.isEmpty && labelIds.isEmpty;

  bool get hasPriorityFilter => priorities.isNotEmpty;
  bool get hasProjectFilter => projectIds.isNotEmpty;
  bool get hasLabelFilter => labelIds.isNotEmpty;

  TaskFilter copyWith({Set<Priority>? priorities, Set<String>? projectIds, Set<String>? labelIds}) {
    return TaskFilter(
      priorities: priorities ?? this.priorities,
      projectIds: projectIds ?? this.projectIds,
      labelIds: labelIds ?? this.labelIds,
    );
  }

  bool applyToTask(Task task, List<String> inheritedLabelIds) {
    if (isEmpty) return true;

    if (hasPriorityFilter && !priorities.contains(task.priority)) {
      return false;
    }

    if (hasProjectFilter) {
      if (task.projectId == null) return false;
      if (!projectIds.contains(task.projectId)) return false;
    }

    if (hasLabelFilter) {
      final combinedLabelIds = {...task.labelIds, ...inheritedLabelIds};
      if (combinedLabelIds.isEmpty) return false;
      // Check if any of the task's combined labels are in the filter
      if (!combinedLabelIds.any((id) => labelIds.contains(id))) {
        return false;
      }
    }

    return true;
  }

  // For filtering projects on the projects screen
  bool applyToProject(Project project) {
    if (isEmpty) return true;

    if (hasPriorityFilter && !priorities.contains(project.priority)) {
      return false;
    }

    if (hasLabelFilter) {
      if (project.labelIds.isEmpty) return false;
      if (!project.labelIds.any((id) => labelIds.contains(id))) {
        return false;
      }
    }

    return true;
  }

  TaskFilter limitTo({bool priority = true, bool projects = true, bool labels = true}) {
    return TaskFilter(
      priorities: priority ? priorities : const {},
      projectIds: projects ? projectIds : const {},
      labelIds: labels ? labelIds : const {},
    );
  }
}
