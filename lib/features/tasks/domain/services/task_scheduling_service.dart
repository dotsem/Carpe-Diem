import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:intl/intl.dart';

class TaskSchedulingService {
  static Future<void> autoScheduleDeadlines({
    required ITaskRepository repo,
    required DateTime today,
  }) async {
    final backlog = await repo.getUnscheduled();
    final normalizedToday = today.normalize;

    for (final task in backlog) {
      if (task.deadline != null) {
        final normalizedDeadline = task.deadline!.normalize;
        if (normalizedDeadline.isBefore(
          normalizedToday.add(const Duration(days: 1)),
        )) {
          final updated = task.copyWith(scheduledDate: normalizedDeadline);
          await repo.update(updated);
        }
      }
    }
  }

  static String _formatDateLabel(DateTime date) {
    if (date.isToday) return 'today';
    if (date.isTomorrow) return 'tomorrow';
    return DateFormat('MMM d').format(date);
  }

  static Command buildScheduleCascadeCommand({
    required ITaskRepository repo,
    required Task task,
    required DateTime date,
    required bool cascadeChildren,
    required List<Task> subtasks,
  }) {
    final normalizedDate = date.normalize;
    final updatedParent = task.copyWith(scheduledDate: normalizedDate);
    final dateLabel = _formatDateLabel(date);

    if (cascadeChildren) {
      final incompleteSubtasks = subtasks.where((t) => !t.isCompleted).toList();
      if (incompleteSubtasks.isNotEmpty) {
        final commands = <Command>[
          UpdateCommand(
            repo: repo,
            previous: task,
            next: updatedParent,
            displayName: task.title,
            customDescription: 'Scheduled "${task.title}" for $dateLabel',
          ),
        ];
        for (final subtask in incompleteSubtasks) {
          final updatedSubtask = subtask.copyWith(
            scheduledDate: normalizedDate,
          );
          commands.add(
            UpdateCommand(
              repo: repo,
              previous: subtask,
              next: updatedSubtask,
              displayName: subtask.title,
              customDescription:
                  'Scheduled subtask "${subtask.title}" for $dateLabel',
            ),
          );
        }
        final actionWord = task.scheduledDate != null
            ? 'Rescheduled'
            : 'Scheduled';
        return CompoundCommand(
          commands,
          '$actionWord "${task.title}" and ${incompleteSubtasks.length} subtask(s) for $dateLabel',
        );
      }
    }

    return UpdateCommand(
      repo: repo,
      previous: task,
      next: updatedParent,
      displayName: task.title,
      customDescription: 'Scheduled "${task.title}" for $dateLabel',
    );
  }

  static Command buildUnscheduleCascadeCommand({
    required ITaskRepository repo,
    required Task task,
    required bool resetStatus,
    required bool unscheduleChildren,
    required List<Task> subtasks,
  }) {
    final updatedParent = task.copyWith(
      clearScheduledDate: true,
      status: resetStatus ? TaskStatus.todo : task.status,
    );

    if (unscheduleChildren) {
      final scheduledSubtasks = subtasks
          .where((t) => t.scheduledDate != null)
          .toList();
      if (scheduledSubtasks.isNotEmpty) {
        final commands = <Command>[
          UpdateCommand(
            repo: repo,
            previous: task,
            next: updatedParent,
            displayName: task.title,
            customDescription: 'Unscheduled "${task.title}"',
          ),
        ];
        for (final subtask in scheduledSubtasks) {
          final updatedSubtask = subtask.copyWith(
            clearScheduledDate: true,
            status: resetStatus ? TaskStatus.todo : subtask.status,
          );
          commands.add(
            UpdateCommand(
              repo: repo,
              previous: subtask,
              next: updatedSubtask,
              displayName: subtask.title,
              customDescription: 'Unscheduled subtask "${subtask.title}"',
            ),
          );
        }
        return CompoundCommand(
          commands,
          'Unscheduled "${task.title}" and ${scheduledSubtasks.length} subtask(s)',
        );
      }
    }

    return UpdateCommand(
      repo: repo,
      previous: task,
      next: updatedParent,
      displayName: task.title,
      customDescription: 'Unscheduled "${task.title}"',
    );
  }

  static Future<Command?> buildBulkScheduleCommand({
    required ITaskRepository repo,
    required List<String> taskIds,
    required DateTime date,
    required Future<Task?> Function(String id) getTaskById,
  }) async {
    final normalizedDate = date.normalize;
    final dateLabel = _formatDateLabel(date);
    final commands = <Command>[];

    for (final id in taskIds) {
      final task = await getTaskById(id);
      if (task != null) {
        final updated = task.copyWith(scheduledDate: normalizedDate);
        commands.add(
          UpdateCommand(
            repo: repo,
            previous: task,
            next: updated,
            displayName: task.title,
            customDescription: 'Scheduled "${task.title}" for $dateLabel',
          ),
        );

        final subtasks = await repo.getByParent(task.id);
        for (final subtask in subtasks) {
          if (subtask.scheduledDate == null &&
              !subtask.isCompleted &&
              !taskIds.contains(subtask.id)) {
            commands.add(
              UpdateCommand(
                repo: repo,
                previous: subtask,
                next: subtask.copyWith(scheduledDate: normalizedDate),
                displayName: subtask.title,
                customDescription:
                    'Scheduled subtask "${subtask.title}" for $dateLabel',
              ),
            );
          }
        }
      }
    }

    if (commands.isEmpty) return null;
    if (commands.length == 1) return commands.first;
    return CompoundCommand(
      commands,
      'Scheduled ${commands.length} tasks for $dateLabel',
    );
  }

  static Task? pickRandomTask(List<Task> availableTasks) {
    final unblocked = availableTasks
        .where((t) => t.blockedById == null && !t.isCompleted)
        .toList();
    if (unblocked.isEmpty) return null;
    final index = DateTime.now().microsecondsSinceEpoch % unblocked.length;
    return unblocked[index];
  }
}
