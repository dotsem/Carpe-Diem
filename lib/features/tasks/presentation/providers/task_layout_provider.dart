import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';

const String keyTaskLayout = 'task_layout';

class TaskLayoutNotifier extends Notifier<TaskLayout> {
  late final IKeyValueRepository _repo;

  @override
  TaskLayout build() {
    _repo = ref.watch(keyValueRepositoryProvider);
    return TaskLayout.list;
  }

  Future<void> loadTaskLayout() async {
    final saved = await _repo.get(keyTaskLayout);
    if (saved != null) {
      state = TaskLayout.fromString(saved);
    }
  }

  Future<void> setLayout(TaskLayout layout) async {
    state = layout;
    try {
      await _repo.set(keyTaskLayout, layout.name);
    } catch (e) {
      debugPrint('Failed to save task layout: $e');
    }
  }

  Future<void> toggleLayout() =>
      setLayout(state == TaskLayout.list ? TaskLayout.kanban : TaskLayout.list);
}

final taskLayoutProvider = NotifierProvider<TaskLayoutNotifier, TaskLayout>(
  TaskLayoutNotifier.new,
);
