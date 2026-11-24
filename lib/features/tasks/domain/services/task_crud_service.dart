import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/domain/task_draft.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';
import 'package:uuid/uuid.dart';

class TaskCrudService {
  static const _uuid = Uuid();
  final ITaskRepository _repo;
  final TaskPrefs Function() _prefs;

  const TaskCrudService(this._repo, this._prefs);

  TaskReorderService get _reorder => TaskReorderService(_repo, _prefs);
  DeadlinePropagationService get _propagation =>
      DeadlinePropagationService(_repo, _prefs);
  SubtaskService get _subtasks => SubtaskService(_repo);

  Future<Task> buildNewTask(TaskDraft draft) async {
    var scheduledDate = draft.scheduledDate;
    var projectId = draft.projectId;
    if (draft.parentId != null) {
      final parent = await _repo.getById(draft.parentId!);
      if (parent != null) {
        scheduledDate ??= parent.scheduledDate;
        projectId ??= parent.projectId;
      }
    }
    final rawList = await _reorder.getRelevantTasksList(
      parentId: draft.parentId,
      projectId: projectId,
      scheduledDate: scheduledDate,
    );
    final isUrgent = draft.isUrgent || draft.placement == TaskPlacement.urgent;
    final dummy = Task(
      id: '',
      title: '',
      parentId: draft.parentId,
      projectId: projectId,
      isUrgent: isUrgent,
      deadline: draft.deadline?.normalize,
      scheduledDate: scheduledDate?.normalize,
      createdAt: DateTime.now(),
    );
    final prefs = _prefs();
    final active = rawList
        .where((task) => TaskReorderEngine.inSameGroup(task, dummy, prefs))
        .toList();
    return Task(
      id: _uuid.v4(),
      title: draft.title,
      description: draft.description,
      scheduledDate: scheduledDate?.normalize,
      projectId: projectId,
      isUrgent: isUrgent,
      deadline: draft.deadline?.normalize,
      createdAt: DateTime.now(),
      blockedById: draft.blockedById,
      parentId: draft.parentId,
      sortOrder: _reorder.computeSortOrder(
        placement: draft.placement,
        activeList: active,
      ),
      labelIds: draft.labelIds,
      tagIds: draft.tagIds,
    );
  }

  Future<Task> resolveUpdatedTask({
    required Task task,
    TaskPlacement? placement,
  }) async {
    if (placement == null) return task;
    final rawList = await _reorder.getRelevantTasksList(
      parentId: task.parentId,
      projectId: task.projectId,
      scheduledDate: task.scheduledDate,
    );
    final target = task.copyWith(
      isUrgent: task.isUrgent || placement == TaskPlacement.urgent,
    );
    final prefs = _prefs();
    final active = rawList
        .where((candidate) => candidate.id != task.id)
        .where(
          (candidate) =>
              TaskReorderEngine.inSameGroup(candidate, target, prefs),
        )
        .toList();
    return target.copyWith(
      sortOrder: _reorder.computeSortOrder(
        placement: placement,
        activeList: active,
      ),
    );
  }

  Future<Command> buildCreateWithPropagationCommand({
    required Task task,
  }) async {
    final create = CreateCommand(
      repo: _repo,
      item: task,
      id: task.id,
      displayName: task.title,
    );
    final propagation = await _propagation.buildPropagationCommands(task);
    if (propagation.isEmpty) return create;
    return CompoundCommand([
      create,
      ...propagation,
    ], 'Create "${task.title}" with propagated deadline');
  }

  Future<Command> buildUpdateWithPropagationCommand({
    required Task previous,
    required Task next,
  }) async {
    final update = UpdateCommand(
      repo: _repo,
      previous: previous,
      next: next,
      displayName: next.title,
    );
    final propagation = await _propagation.buildPropagationCommands(next);
    if (propagation.isEmpty) return update;
    return CompoundCommand([
      update,
      ...propagation,
    ], 'Update "${next.title}" with propagated deadline');
  }

  Future<Command> buildDeleteCommand({
    required Task task,
    required bool deleteSubtasks,
  }) async {
    final subtasks = await _subtasks.getAllSubtasksFromRepo(task.id);
    if (subtasks.isEmpty) {
      return DeleteCommand(
        repo: _repo,
        item: task,
        id: task.id,
        displayName: task.title,
      );
    }
    final commands = <Command>[
      for (final subtask in subtasks)
        if (deleteSubtasks)
          DeleteCommand(
            repo: _repo,
            item: subtask,
            id: subtask.id,
            displayName: subtask.title,
          )
        else
          UpdateCommand(
            repo: _repo,
            previous: subtask,
            next: subtask.copyWith(parentId: null),
            displayName: subtask.title,
          ),
      DeleteCommand(
        repo: _repo,
        item: task,
        id: task.id,
        displayName: task.title,
      ),
    ];
    return CompoundCommand(
      commands,
      deleteSubtasks
          ? 'Delete "${task.title}" and ${subtasks.length} subtask(s)'
          : 'Delete parent "${task.title}" (preserve subtasks)',
    );
  }
}
