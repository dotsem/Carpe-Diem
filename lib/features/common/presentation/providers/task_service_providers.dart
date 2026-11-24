import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_crud_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_scheduling_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskReorderServiceProvider = Provider<TaskReorderService>((ref) {
  return TaskReorderService(
    ref.watch(taskRepositoryProvider),
    () => ref.read(settingsProvider).taskPrefs,
  );
});

final taskCrudServiceProvider = Provider<TaskCrudService>((ref) {
  return TaskCrudService(
    ref.watch(taskRepositoryProvider),
    () => ref.read(settingsProvider).taskPrefs,
  );
});

final subtaskServiceProvider = Provider<SubtaskService>((ref) {
  return SubtaskService(ref.watch(taskRepositoryProvider));
});

final taskSchedulingServiceProvider = Provider<TaskSchedulingService>((ref) {
  return TaskSchedulingService(ref.watch(taskRepositoryProvider));
});

final deadlinePropagationServiceProvider = Provider<DeadlinePropagationService>(
  (ref) {
    return DeadlinePropagationService(
      ref.watch(taskRepositoryProvider),
      () => ref.read(settingsProvider).taskPrefs,
    );
  },
);
