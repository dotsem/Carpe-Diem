import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class DeadlinePropagationService {
  static Future<List<UpdateCommand>> buildPropagationCommands({
    required ITaskRepository repo,
    required Task task,
    required bool inheritParentDeadline,
    Set<String>? visited,
  }) async {
    if (!inheritParentDeadline ||
        task.deadline == null ||
        task.blockedById == null) {
      return const [];
    }

    final localVisited = visited ?? <String>{};
    if (localVisited.contains(task.id)) return const [];
    localVisited.add(task.id);

    final blocker = await repo.getById(task.blockedById!);
    if (blocker == null) return const [];

    final commands = <UpdateCommand>[];
    if (blocker.deadline == null || blocker.deadline!.isAfter(task.deadline!)) {
      final updatedBlocker = blocker.copyWith(deadline: task.deadline);
      commands.add(
        UpdateCommand(
          repo: repo,
          previous: blocker,
          next: updatedBlocker,
          displayName: blocker.title,
        ),
      );
      final recursiveCommands = await buildPropagationCommands(
        repo: repo,
        task: updatedBlocker,
        inheritParentDeadline: inheritParentDeadline,
        visited: localVisited,
      );
      commands.addAll(recursiveCommands);
    }
    return commands;
  }
}
