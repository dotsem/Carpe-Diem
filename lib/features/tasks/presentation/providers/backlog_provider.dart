import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BacklogNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() {
    loadBacklog();
    return const [];
  }

  Future<void> loadBacklog() async {
    final repo = ref.read(taskRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final backlog = await repo.getUnscheduled(
      prioritizeDeadlines: settings.prioritizeDeadlines,
    );
    state = backlog;
  }
}

final backlogProvider = NotifierProvider<BacklogNotifier, List<Task>>(() {
  return BacklogNotifier();
});
