import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class DeadlinePropagationService {
  static Future<void> propagateDeadline({
    required ITaskRepository repo,
    required Task task,
    required bool inheritParentDeadline,
    Set<String>? visited,
  }) async {
    if (!inheritParentDeadline ||
        task.deadline == null ||
        task.blockedById == null) {
      return;
    }

    final localVisited = visited ?? <String>{};
    if (localVisited.contains(task.id)) return;
    localVisited.add(task.id);

    final blocker = await repo.getById(task.blockedById!);
    if (blocker == null) return;

    if (blocker.deadline == null || blocker.deadline!.isAfter(task.deadline!)) {
      final updatedBlocker = blocker.copyWith(deadline: task.deadline);
      await repo.update(updatedBlocker);
      await propagateDeadline(
        repo: repo,
        task: updatedBlocker,
        inheritParentDeadline: inheritParentDeadline,
        visited: localVisited,
      );
    }
  }
}
