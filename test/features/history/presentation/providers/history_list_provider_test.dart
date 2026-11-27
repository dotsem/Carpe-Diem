import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_list_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('historyListProvider', () {
    late MockHistoryRepository history;
    late MockKeyValueRepository settings;
    late ProviderContainer container;
    final overview = HistoryOverview.empty();

    setUpAll(() => registerFallbackValue(DateTime(2026)));

    setUp(() {
      history = MockHistoryRepository();
      settings = MockKeyValueRepository();
      when(
        () => history.getHistoryOverview(
          any(),
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => overview);
      container = ProviderContainer(
        overrides: [
          historyRepositoryProvider.overrideWithValue(history),
          keyValueRepositoryProvider.overrideWithValue(settings),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loads the first page', () async {
      final range = container.read(historyListProvider).queryRange;
      final tasks = _tasks(25);
      _stubPage(history, range, offset: 0, tasks: tasks);

      await container.read(historyListProvider.notifier).load();

      final state = container.read(historyListProvider);
      expect(state.completedTasks, tasks);
      expect(state.overview, overview);
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('a settings change keeps the picked date range', () async {
      final picked = DateTimeRange(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 8),
      );
      when(() => settings.set(any(), any())).thenAnswer((_) async {});

      container.read(historyListProvider.notifier).setDateRange(picked);
      await container.read(settingsProvider.notifier).setCompactMode(true);

      expect(container.read(historyListProvider).dateRange, picked);
    });

    test('loadMore appends the next page', () async {
      final range = container.read(historyListProvider).queryRange;
      final firstPage = _tasks(25);
      final nextPage = _tasks(2, start: 25);
      _stubPage(history, range, offset: 0, tasks: firstPage);
      _stubPage(history, range, offset: 25, tasks: nextPage);
      final notifier = container.read(historyListProvider.notifier);

      await notifier.load();
      await notifier.loadMore();

      expect(container.read(historyListProvider).completedTasks, [
        ...firstPage,
        ...nextPage,
      ]);
    });

    test('hasMore turns false when a page is short', () async {
      final range = container.read(historyListProvider).queryRange;
      _stubPage(history, range, offset: 0, tasks: _tasks(2));

      await container.read(historyListProvider.notifier).load();

      expect(container.read(historyListProvider).hasMore, isFalse);
    });

    test('changing the date range resets the offset', () async {
      final initialRange = container.read(historyListProvider).queryRange;
      final notifier = container.read(historyListProvider.notifier);
      final picked = DateTimeRange(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 8),
      );
      final pickedQueryRange = DateTimeRange(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 8, 23, 59, 59),
      );
      _stubPage(history, initialRange, offset: 0, tasks: _tasks(25));
      _stubPage(
        history,
        initialRange,
        offset: 25,
        tasks: _tasks(25, start: 25),
      );
      _stubPage(history, pickedQueryRange, offset: 0, tasks: _tasks(1));

      await notifier.load();
      await notifier.loadMore();
      notifier.setDateRange(picked);
      await notifier.load();

      verify(
        () => history.getCompletedInRange(
          pickedQueryRange.start,
          pickedQueryRange.end,
          limit: 25,
          offset: 0,
          filter: const TaskFilter(),
        ),
      ).called(1);
    });
  });
}

List<Task> _tasks(int count, {int start = 0}) => [
  for (var index = start; index < start + count; index++)
    createTestTask(id: 'task-$index'),
];

void _stubPage(
  MockHistoryRepository history,
  DateTimeRange range, {
  required int offset,
  required List<Task> tasks,
}) {
  when(
    () => history.getCompletedInRange(
      range.start,
      range.end,
      limit: 25,
      offset: offset,
      filter: const TaskFilter(),
    ),
  ).thenAnswer((_) async => tasks);
}
