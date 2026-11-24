import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  late MockTaskRepository tasks;
  late MockHistoryRepository history;
  late MockKeyValueRepository settings;
  late ProviderContainer container;

  setUp(() {
    tasks = MockTaskRepository();
    history = MockHistoryRepository();
    settings = MockKeyValueRepository();
    when(() => settings.set(any(), any())).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(tasks),
        historyRepositoryProvider.overrideWithValue(history),
        keyValueRepositoryProvider.overrideWithValue(settings),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'cleans retained history and invokes callback only after deletions',
    () async {
      var callbacks = 0;
      when(() => tasks.cleanupHistory(30)).thenAnswer((_) async => 2);
      await container.read(settingsProvider.notifier).setHistoryRetention(30);

      await container
          .read(taskHistoryProvider.notifier)
          .cleanupHistory(onCleanup: () async => callbacks++);

      expect(callbacks, 1);
      when(() => tasks.cleanupHistory(30)).thenAnswer((_) async => 0);
      await container
          .read(taskHistoryProvider.notifier)
          .cleanupHistory(onCleanup: () async => callbacks++);
      expect(callbacks, 1);
    },
  );

  test('does not call repository when retention is disabled', () async {
    await container
        .read(taskHistoryProvider.notifier)
        .cleanupHistory(onCleanup: () async {});

    verifyNever(() => tasks.cleanupHistory(any()));
  });

  test('delegates history queries with all arguments', () async {
    final start = DateTime(2026);
    final end = DateTime(2027);
    const filter = TaskFilter(isUrgent: true);
    final task = Task(id: 'task', title: 'Task', createdAt: start);
    final overview = HistoryOverview.empty();
    when(
      () => history.getCompletedInRange(
        start,
        end,
        limit: 5,
        offset: 2,
        filter: filter,
      ),
    ).thenAnswer((_) async => [task]);
    when(
      () => history.getHistoryOverview(start, end, filter: filter),
    ).thenAnswer((_) async => overview);
    when(() => history.getFirstCompletedDate()).thenAnswer((_) async => start);
    final notifier = container.read(taskHistoryProvider.notifier);

    expect(
      await notifier.getCompletedTasks(
        start,
        end,
        limit: 5,
        offset: 2,
        filter: filter,
      ),
      [task],
    );
    expect(
      await notifier.getHistoryOverview(start, end, filter: filter),
      overview,
    );
    expect(await notifier.getFirstTaskDate(), start);
  });

  test('uses current time when no completion exists', () async {
    when(() => history.getFirstCompletedDate()).thenAnswer((_) async => null);
    final before = DateTime.now();

    final result = await container
        .read(taskHistoryProvider.notifier)
        .getFirstTaskDate();

    expect(result.isBefore(before), isFalse);
  });
}
