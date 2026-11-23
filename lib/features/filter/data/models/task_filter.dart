import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_filter.freezed.dart';

@freezed
abstract class TaskFilter with _$TaskFilter {
  const TaskFilter._();
  const factory TaskFilter({
    bool? isUrgent,
    @Default({}) Set<String> projectIdsIncluded,
    @Default({}) Set<String> labelIdsIncluded,
    @Default({}) Set<String> tagIdsIncluded,
    @Default({}) Set<String> projectIdsExcluded,
    @Default({}) Set<String> labelIdsExcluded,
    @Default({}) Set<String> tagIdsExcluded,
  }) = _TaskFilter;

  bool get isEmpty =>
      isUrgent == null &&
      projectIdsIncluded.isEmpty &&
      labelIdsIncluded.isEmpty &&
      tagIdsIncluded.isEmpty &&
      projectIdsExcluded.isEmpty &&
      labelIdsExcluded.isEmpty &&
      tagIdsExcluded.isEmpty;

  bool get hasUrgencyFilter => isUrgent != null;
  bool get hasProjectFilter =>
      projectIdsIncluded.isNotEmpty || projectIdsExcluded.isNotEmpty;
  bool get hasLabelFilter =>
      labelIdsIncluded.isNotEmpty || labelIdsExcluded.isNotEmpty;
  bool get hasTagFilter =>
      tagIdsIncluded.isNotEmpty || tagIdsExcluded.isNotEmpty;

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
    if (projectIdsIncluded.isNotEmpty &&
        (task.projectId == null ||
            !projectIdsIncluded.contains(task.projectId))) {
      return false;
    }

    if (hasLabelFilter) {
      final combinedLabelIds = {...task.labelIds, ...inheritedLabelIds};
      if (combinedLabelIds.any(labelIdsExcluded.contains)) {
        return false;
      }
      if (labelIdsIncluded.isNotEmpty &&
          !combinedLabelIds.any(labelIdsIncluded.contains)) {
        return false;
      }
    }

    if (hasTagFilter) {
      if (task.tagIds.any(tagIdsExcluded.contains)) {
        return false;
      }
      if (tagIdsIncluded.isNotEmpty &&
          !task.tagIds.any(tagIdsIncluded.contains)) {
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
      if (labelIdsIncluded.isNotEmpty &&
          !project.labelIds.any(labelIdsIncluded.contains)) {
        return false;
      }
    }

    return true;
  }

  TaskFilter limitTo({
    bool priority = true,
    bool projects = true,
    bool labels = true,
    bool tags = true,
  }) {
    return TaskFilter(
      isUrgent: priority ? isUrgent : null,
      projectIdsIncluded: projects ? projectIdsIncluded : const {},
      labelIdsIncluded: labels ? labelIdsIncluded : const {},
      tagIdsIncluded: tags ? tagIdsIncluded : const {},

      projectIdsExcluded: projects ? projectIdsExcluded : const {},
      labelIdsExcluded: labels ? labelIdsExcluded : const {},
      tagIdsExcluded: tags ? tagIdsExcluded : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isUrgent': isUrgent,
      'projectIdsIncluded': projectIdsIncluded.toList(),
      'labelIdsIncluded': labelIdsIncluded.toList(),
      'tagIdsIncluded': tagIdsIncluded.toList(),

      'projectIdsExcluded': projectIdsExcluded.toList(),
      'labelIdsExcluded': labelIdsExcluded.toList(),
      'tagIdsExcluded': tagIdsExcluded.toList(),
    };
  }

  factory TaskFilter.fromMap(Map<String, dynamic> map) {
    Set<String> stringSetFromList(List<dynamic>? list) {
      return Set<String>.from((list ?? []).map((e) => e.toString()));
    }

    return TaskFilter(
      isUrgent: map['isUrgent'] as bool?,
      projectIdsIncluded: stringSetFromList(
        map['projectIdsIncluded'] as List<dynamic>?,
      ),
      labelIdsIncluded: stringSetFromList(
        map['labelIdsIncluded'] as List<dynamic>?,
      ),
      tagIdsIncluded: stringSetFromList(
        map['tagIdsIncluded'] as List<dynamic>?,
      ),

      projectIdsExcluded: stringSetFromList(
        map['projectIdsExcluded'] as List<dynamic>?,
      ),
      labelIdsExcluded: stringSetFromList(
        map['labelIdsExcluded'] as List<dynamic>?,
      ),
      tagIdsExcluded: stringSetFromList(
        map['tagIdsExcluded'] as List<dynamic>?,
      ),
    );
  }
}

enum FilterInteractionMethod {
  cycle,
  leftRightClick;

  static FilterInteractionMethod fromString(String val) {
    return FilterInteractionMethod.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FilterInteractionMethod.cycle,
    );
  }
}
