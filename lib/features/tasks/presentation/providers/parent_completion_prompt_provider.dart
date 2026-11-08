import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a parent task whose subtasks just all got completed, so the shell
/// can ask the user whether to complete the parent too.
class ParentCompletionPromptNotifier extends Notifier<Task?> {
  @override
  Task? build() => null;

  Future<void> checkAfterCompleting(Task task) async {
    final parent = await SubtaskService.findCompletableParent(
      repo: ref.read(taskRepositoryProvider),
      task: task,
    );
    if (parent != null) state = parent;
  }

  void clear() => state = null;
}

final parentCompletionPromptProvider =
    NotifierProvider<ParentCompletionPromptNotifier, Task?>(
      ParentCompletionPromptNotifier.new,
    );
