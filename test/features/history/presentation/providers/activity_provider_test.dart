import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/history/presentation/providers/activity_provider.dart';
import 'package:carpe_diem/features/history/presentation/providers/first_completed_task_date_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  late MockHistoryRepository history;
  late MockHistoryInsightsRepository insights;
  late ProviderContainer container;

  setUp(() {
    history = MockHistoryRepository();
    insights = MockHistoryInsightsRepository();
    container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(history),
        historyInsightsRepositoryProvider.overrideWithValue(insights),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'returns an empty activity window when there are no completions',
    () async {
      when(() => history.getFirstCompletedDate()).thenAnswer((_) async => null);

      final result = await container.read(activityProvider(2026).future);

      expect(result.dailyCounts, isEmpty);
      expect(result.start, DateTime(2026));
      expect(
        result.end,
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
      verifyNever(() => insights.getCompletionsSince(any()));
    },
  );

  test('counts in-window completion days and excludes later days', () async {
    when(
      () => history.getFirstCompletedDate(),
    ).thenAnswer((_) async => DateTime(2025, 4));
    when(() => insights.getCompletionsSince(any())).thenAnswer(
      (_) async => [
        (projectId: 'p', completedAt: DateTime(2026, 2, 3, 10)),
        (projectId: 'p', completedAt: DateTime(2026, 2, 3, 18)),
        (projectId: 'p', completedAt: DateTime(2027)),
      ],
    );

    final result = await container.read(activityProvider(2026).future);

    expect(result.dailyCounts, {DateTime(2026, 2, 3): 2});
  });

  test('lists years down to the first completion year', () async {
    when(
      () => history.getFirstCompletedDate(),
    ).thenAnswer((_) async => DateTime(DateTime.now().year - 2));

    final years = await container.read(activityYearsProvider.future);

    expect(years, [
      DateTime.now().year,
      DateTime.now().year - 1,
      DateTime.now().year - 2,
    ]);
  });

  test('returns no years and exposes first completion directly', () async {
    when(() => history.getFirstCompletedDate()).thenAnswer((_) async => null);

    expect(await container.read(activityYearsProvider.future), isEmpty);
    expect(await container.read(firstCompletedTaskDateProvider.future), isNull);
  });
}
