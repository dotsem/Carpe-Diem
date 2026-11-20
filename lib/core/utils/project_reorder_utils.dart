import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';

class ProjectReorderUtils {
  /// Compute new sort order string for inserting a project at slot [slotIndex] in [remainingProjects].
  /// [slotIndex] ranges from 0 to `remainingProjects.length`.
  static String computeSortOrderForSlot({
    required Project draggedProject,
    required List<Project> remainingProjects,
    required int slotIndex,
  }) {
    if (remainingProjects.isEmpty) {
      return LexoRank.defaultRank;
    }

    final isUrgent = draggedProject.isUrgent;

    var groupStart = -1;
    var groupEnd = -1;

    for (var i = 0; i < remainingProjects.length; i++) {
      if (remainingProjects[i].isUrgent == isUrgent) {
        if (groupStart == -1) groupStart = i;
        groupEnd = i;
      }
    }

    if (groupStart == -1) {
      return LexoRank.defaultRank;
    }

    final group = remainingProjects.sublist(groupStart, groupEnd + 1);
    return LexoRank.generateAtSlot(
      group.map((p) => p.sortOrder).toList(),
      slotIndex - groupStart,
    );
  }

  /// Calculate the new sort order for a project moved to [newIndex] in [projects].
  /// Returns the new sort order string, or null if no change is needed.
  static String? handleReorder({
    required List<Project> projects,
    required Project draggedProject,
    required int newIndex,
  }) {
    final oldIndex = projects.indexWhere((p) => p.id == draggedProject.id);
    if (oldIndex == -1 || oldIndex == newIndex) return null;

    final remainingProjects = projects
        .where((p) => p.id != draggedProject.id)
        .toList();

    return computeSortOrderForSlot(
      draggedProject: draggedProject,
      remainingProjects: remainingProjects,
      slotIndex: newIndex,
    );
  }
}
