import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadedProjectDetails {
  final List<Task> projectTasks;
  final List<String> inheritedLabelIds;
  final String? selectedProjectId;
  final DateTime? scheduledDate;
  final DateTime? deadline;

  const LoadedProjectDetails({
    required this.projectTasks,
    required this.inheritedLabelIds,
    required this.selectedProjectId,
    required this.scheduledDate,
    required this.deadline,
  });
}

abstract final class TaskFormDetailsLoader {
  static Future<LoadedProjectDetails?> loadDetails({
    required WidgetRef ref,
    required bool isEditing,
    required String? parentId,
    required String? currentProjectId,
    required DateTime? currentScheduledDate,
    required DateTime? currentDeadline,
  }) async {
    final settings = ref.read(settingsProvider);
    List<String> parentLabelIds = [];
    String? selectedProjectId = currentProjectId;
    DateTime? scheduledDate = currentScheduledDate;
    DateTime? deadline = currentDeadline;

    if (!isEditing && parentId != null) {
      Task? parentTask = ref.read(taskProvider).getById(parentId);
      if (parentTask == null) {
        final repo = ref.read(taskRepositoryProvider);
        parentTask = await repo.getById(parentId);
      }
      if (parentTask != null) {
        selectedProjectId ??= parentTask.projectId;
        scheduledDate ??= parentTask.scheduledDate;
        deadline ??= parentTask.deadline;
        parentLabelIds = parentTask.labelIds;
      }
    }

    if (!isEditing && selectedProjectId == null && parentId == null) {
      selectedProjectId = settings.defaultProjectId;
    }

    if (selectedProjectId == null) {
      return LoadedProjectDetails(
        projectTasks: const [],
        inheritedLabelIds: parentLabelIds.toSet().toList(),
        selectedProjectId: null,
        scheduledDate: scheduledDate,
        deadline: deadline,
      );
    }

    final tasks = await ref
        .read(taskProvider.notifier)
        .getTasksForProject(selectedProjectId);
    final project = ref.read(projectProvider).getById(selectedProjectId);
    final combinedInheritedLabels = <String>{
      ...?project?.labelIds,
      ...parentLabelIds,
    }.toList();

    if (!isEditing &&
        settings.inheritProjectDeadline &&
        project?.deadline != null) {
      deadline ??= project?.deadline;
    }

    return LoadedProjectDetails(
      projectTasks: tasks,
      inheritedLabelIds: combinedInheritedLabels,
      selectedProjectId: selectedProjectId,
      scheduledDate: scheduledDate,
      deadline: deadline,
    );
  }
}
