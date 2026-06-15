import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskFilter {
  final Set<Priority> prioritiesIncluded;
  final Set<String> projectIdsIncluded;
  final Set<String> labelIdsIncluded;
  final Set<Priority> prioritiesExcluded;
  final Set<String> projectIdsExcluded;
  final Set<String> labelIdsExcluded;

  const TaskFilter({
    this.prioritiesIncluded = const {},
    this.projectIdsIncluded = const {},
    this.labelIdsIncluded = const {},
    this.prioritiesExcluded = const {},
    this.projectIdsExcluded = const {},
    this.labelIdsExcluded = const {},
  });

  bool get isEmpty =>
      prioritiesIncluded.isEmpty &&
      projectIdsIncluded.isEmpty &&
      labelIdsIncluded.isEmpty &&
      prioritiesExcluded.isEmpty &&
      projectIdsExcluded.isEmpty &&
      labelIdsExcluded.isEmpty;

  bool get hasPriorityFilter => prioritiesIncluded.isNotEmpty || prioritiesExcluded.isNotEmpty;
  bool get hasProjectFilter => projectIdsIncluded.isNotEmpty || projectIdsExcluded.isNotEmpty;
  bool get hasLabelFilter => labelIdsIncluded.isNotEmpty || labelIdsExcluded.isNotEmpty;

  TaskFilter copyWith({
    Set<Priority>? prioritiesIncluded,
    Set<String>? projectIdsIncluded,
    Set<String>? labelIdsIncluded,
    Set<Priority>? prioritiesExcluded,
    Set<String>? projectIdsExcluded,
    Set<String>? labelIdsExcluded,
  }) {
    return TaskFilter(
      prioritiesIncluded: prioritiesIncluded ?? this.prioritiesIncluded,
      projectIdsIncluded: projectIdsIncluded ?? this.projectIdsIncluded,
      labelIdsIncluded: labelIdsIncluded ?? this.labelIdsIncluded,
      prioritiesExcluded: prioritiesExcluded ?? this.prioritiesExcluded,
      projectIdsExcluded: projectIdsExcluded ?? this.projectIdsExcluded,
      labelIdsExcluded: labelIdsExcluded ?? this.labelIdsExcluded,
    );
  }

  /// @returns true if the task matches the filter
  /// (or no filter has been set for the given category),
  /// false otherwise
  bool applyToTask(Task task, List<String> inheritedLabelIds) {
    if (isEmpty) return true;

    if (prioritiesExcluded.contains(task.priority)) {
      return false;
    }
    if (prioritiesIncluded.isNotEmpty && !prioritiesIncluded.contains(task.priority)) {
      return false;
    }

    if (task.projectId != null && projectIdsExcluded.contains(task.projectId)) {
      return false;
    }
    if (projectIdsIncluded.isNotEmpty && (task.projectId == null || !projectIdsIncluded.contains(task.projectId))) {
      return false;
    }

    if (hasLabelFilter) {
      final combinedLabelIds = {...task.labelIds, ...inheritedLabelIds};
      if (combinedLabelIds.any(labelIdsExcluded.contains)) {
        return false;
      }
      if (labelIdsIncluded.isNotEmpty && !combinedLabelIds.any(labelIdsIncluded.contains)) {
        return false;
      }
    }

    return true;
  }

  /// @returns true if the project matches the filter
  /// (or no filter has been set for the given category),
  /// false otherwise
  bool applyToProject(Project project) {
    if (isEmpty) return true;

    if (prioritiesExcluded.contains(project.priority)) {
      return false;
    }
    if (prioritiesIncluded.isNotEmpty && !prioritiesIncluded.contains(project.priority)) {
      return false;
    }

    if (hasLabelFilter) {
      if (project.labelIds.any(labelIdsExcluded.contains)) {
        return false;
      }
      if (labelIdsIncluded.isNotEmpty && !project.labelIds.any(labelIdsIncluded.contains)) {
        return false;
      }
    }

    return true;
  }


  TaskFilter limitTo({bool priority = true, bool projects = true, bool labels = true}) {
    return TaskFilter(
      prioritiesIncluded: priority ? prioritiesIncluded : const {},
      projectIdsIncluded: projects ? projectIdsIncluded : const {},
      labelIdsIncluded: labels ? labelIdsIncluded : const {},
      prioritiesExcluded: priority ? prioritiesExcluded : const {},
      projectIdsExcluded: projects ? projectIdsExcluded : const {},
      labelIdsExcluded: labels ? labelIdsExcluded : const {},
    );
  }
}

enum FilterInteractionMethod {
  cycle,
  leftRightClick;

  static FilterInteractionMethod fromString(String val) {
    return FilterInteractionMethod.values.firstWhere((e) => e.name == val, orElse: () => FilterInteractionMethod.cycle);
  }
}
