import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subtasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  parentId,
) async {
  ref.watch(taskProvider);
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getByParent(parentId);
});

final parentTaskProvider = FutureProvider.family<Task?, String>((
  ref,
  parentId,
) async {
  ref.watch(taskProvider);
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getById(parentId);
});
