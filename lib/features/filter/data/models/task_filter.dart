import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskFilter {
  final bool? isUrgent;
  final Set<String> projectIdsIncluded;
  final Set<String> labelIdsIncluded;
  final Set<String> projectIdsExcluded;
  final Set<String> labelIdsExcluded;

  const TaskFilter({
    this.isUrgent,
    this.projectIdsIncluded = const {},
    this.labelIdsIncluded = const {},
    this.projectIdsExcluded = const {},
    this.labelIdsExcluded = const {},
  });

  bool get isEmpty =>
      isUrgent == null &&
      projectIdsIncluded.isEmpty &&
      labelIdsIncluded.isEmpty &&
      projectIdsExcluded.isEmpty &&
      labelIdsExcluded.isEmpty;

  bool get hasUrgencyFilter => isUrgent != null;
  bool get hasProjectFilter => projectIdsIncluded.isNotEmpty || projectIdsExcluded.isNotEmpty;
  bool get hasLabelFilter => labelIdsIncluded.isNotEmpty || labelIdsExcluded.isNotEmpty;

  TaskFilter copyWith({
    bool? isUrgent,
    bool clearIsUrgent = false,
    Set<String>? projectIdsIncluded,
    Set<String>? labelIdsIncluded,
    Set<String>? projectIdsExcluded,
    Set<String>? labelIdsExcluded,
  }) {
    return TaskFilter(
      isUrgent: clearIsUrgent ? null : (isUrgent ?? this.isUrgent),
      projectIdsIncluded: projectIdsIncluded ?? this.projectIdsIncluded,
      labelIdsIncluded: labelIdsIncluded ?? this.labelIdsIncluded,
      projectIdsExcluded: projectIdsExcluded ?? this.projectIdsExcluded,
      labelIdsExcluded: labelIdsExcluded ?? this.labelIdsExcluded,
    );
  }

  /// @returns true if the task matches the filter
  /// (or no filter has been set for the given category),
  /// false otherwise
  bool applyToTask(Task task, List<String> inheritedLabelIds) {
    if (isEmpty) return true;

    if (isUrgent != null && task.isUrgent != isUrgent) {
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

    if (isUrgent != null && project.isUrgent != isUrgent) {
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
      isUrgent: priority ? isUrgent : null,
      projectIdsIncluded: projects ? projectIdsIncluded : const {},
      labelIdsIncluded: labels ? labelIdsIncluded : const {},

      projectIdsExcluded: projects ? projectIdsExcluded : const {},
      labelIdsExcluded: labels ? labelIdsExcluded : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isUrgent': isUrgent,
      'projectIdsIncluded': projectIdsIncluded.toList(),
      'labelIdsIncluded': labelIdsIncluded.toList(),

      'projectIdsExcluded': projectIdsExcluded.toList(),
      'labelIdsExcluded': labelIdsExcluded.toList(),
    };
  }

  factory TaskFilter.fromMap(Map<String, dynamic> map) {
    Set<String> stringSetFromList(List<dynamic>? list) {
      return Set<String>.from((list ?? []).map((e) => e.toString()));
    }



    return TaskFilter(
      isUrgent: map['isUrgent'] as bool?,
      projectIdsIncluded: stringSetFromList(map['projectIdsIncluded'] as List<dynamic>?),
      labelIdsIncluded: stringSetFromList(map['labelIdsIncluded'] as List<dynamic>?),

      projectIdsExcluded: stringSetFromList(map['projectIdsExcluded'] as List<dynamic>?),
      labelIdsExcluded: stringSetFromList(map['labelIdsExcluded'] as List<dynamic>?),
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
