import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';

class TaskReorderService {
  final ITaskRepository _repo;
  final TaskPrefs Function() _prefs;

  const TaskReorderService(this._repo, this._prefs);

  String computeSortOrder({
    required TaskPlacement placement,
    required List<Task> activeList,
  }) {
    if (activeList.isEmpty) return LexoRank.defaultRank;
    switch (placement) {
      case TaskPlacement.top || TaskPlacement.urgent:
        return LexoRank.generateTop(
          TaskReorderEngine.getEffectiveRank(activeList, 0),
        );
      case TaskPlacement.middle:
        if (activeList.length == 1) {
          return LexoRank.generateBetween(
            null,
            TaskReorderEngine.getEffectiveRank(activeList, 0),
          );
        }
        final mid = activeList.length ~/ 2;
        return LexoRank.generateBetween(
          TaskReorderEngine.getEffectiveRank(activeList, mid - 1),
          TaskReorderEngine.getEffectiveRank(activeList, mid),
        );
      case TaskPlacement.bottom:
        String? bottom;
        for (var i = activeList.length - 1; i >= 0 && bottom == null; i--) {
          bottom = TaskReorderEngine.getEffectiveRank(activeList, i);
        }
        return LexoRank.generateBottom(bottom);
    }
  }

  Future<List<Task>> getRelevantTasksList({
    required String? parentId,
    required String? projectId,
    required DateTime? scheduledDate,
  }) {
    final prefs = _prefs();
    if (parentId != null) return _repo.getByParent(parentId);
    if (projectId != null && scheduledDate == null) {
      return _repo.getByProjectUnscheduled(
        projectId,
        prioritizeDeadlines: prefs.prioritizeDeadlines,
        prioritizeOverdue: prefs.prioritizeOverdue,
      );
    }
    if (scheduledDate == null) {
      return _repo.getUnscheduled(
        prioritizeDeadlines: prefs.prioritizeDeadlines,
        prioritizeOverdue: prefs.prioritizeOverdue,
      );
    }
    return _repo.getByDate(
      scheduledDate,
      prioritizeDeadlines: prefs.prioritizeDeadlines,
      prioritizeOverdue: prefs.prioritizeOverdue,
    );
  }

  Command buildReorderCommand({required Task previous, required Task next}) =>
      UpdateCommand(
        repo: _repo,
        previous: previous,
        next: next,
        displayName: next.title,
        customDescription: 'Reorder ${_repo.repositoryName}: "${next.title}"',
      );

  Future<Command?> buildBulkReorderCommand({
    required Map<String, String> updates,
    bool isPlanOrder = false,
  }) async {
    final commands = <Command>[];
    for (final entry in updates.entries) {
      final oldTask = await _repo.getById(entry.key);
      if (oldTask == null) continue;
      final updated = isPlanOrder
          ? oldTask.copyWith(planSortOrder: entry.value)
          : oldTask.copyWith(sortOrder: entry.value);
      commands.add(
        UpdateCommand(
          repo: _repo,
          previous: oldTask,
          next: updated,
          displayName: oldTask.title,
          customDescription:
              'Reorder ${_repo.repositoryName}: "${oldTask.title}"',
        ),
      );
    }
    if (commands.isEmpty) return null;
    if (commands.length == 1) return commands.first;
    return CompoundCommand(commands, 'Reorder ${commands.length} tasks');
  }
}
