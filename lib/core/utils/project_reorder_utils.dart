import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';

class ProjectReorderUtils {
  /// Compute new sort order string for inserting a project at slot [slotIndex] in [remainingProjects].
  /// [slotIndex] ranges from 0 to [remainingProjects.length].
  static String computeSortOrderForSlot({
    required Project draggedProject,
    required List<Project> remainingProjects,
    required int slotIndex,
  }) {
    if (remainingProjects.isEmpty) {
      return LexoRankUtils.defaultRank;
    }

    final isUrgent = draggedProject.isUrgent;

    // Find the bounds of the matching isUrgent group in remainingProjects
    int groupStart = -1;
    int groupEnd = -1;

    for (int i = 0; i < remainingProjects.length; i++) {
      if (remainingProjects[i].isUrgent == isUrgent) {
        if (groupStart == -1) groupStart = i;
        groupEnd = i;
      }
    }

    // If there are no other projects in this group, just return default rank
    if (groupStart == -1) {
      return LexoRankUtils.defaultRank;
    }

    if (slotIndex <= groupStart) {
      return LexoRankUtils.generateTop(remainingProjects[groupStart].sortOrder);
    }

    if (slotIndex > groupEnd) {
      return LexoRankUtils.generateBottom(
        remainingProjects[groupEnd].sortOrder,
      );
    }

    return LexoRankUtils.generateBetween(
      remainingProjects[slotIndex - 1].sortOrder,
      remainingProjects[slotIndex].sortOrder,
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
