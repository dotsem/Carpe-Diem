import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_insights_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  late MockHistoryRepository history;
  late MockHistoryInsightsRepository insights;
  late MockProjectRepository projects;
  late MockKeyValueRepository settings;
  late ProviderContainer container;

  setUp(() async {
    history = MockHistoryRepository();
    insights = MockHistoryInsightsRepository();
    projects = MockProjectRepository();
    settings = MockKeyValueRepository();
    when(() => settings.getAll()).thenAnswer((_) async => {});
    when(() => projects.getAll()).thenAnswer(
      (_) async => [
        Project(
          id: 'active',
          name: 'Active',
          color: Colors.blue,
          createdAt: DateTime(2026),
        ),
        Project(
          id: 'inactive',
          name: 'Inactive',
          color: Colors.grey,
          isActive: false,
          createdAt: DateTime(2026),
        ),
      ],
    );
    container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(history),
        historyInsightsRepositoryProvider.overrideWithValue(insights),
        projectRepositoryProvider.overrideWithValue(projects),
        keyValueRepositoryProvider.overrideWithValue(settings),
      ],
    );
    await container.read(projectProvider.notifier).loadProjects();
  });

  tearDown(() => container.dispose());

  test('returns velocity only when event tracking has not started', () async {
    final range = DateTimeRange(start: DateTime(2026), end: DateTime(2026, 2));
    when(
      () => history.getFirstCompletedDate(),
    ).thenAnswer((_) async => DateTime(2025));
    when(() => insights.getCompletionsSince(any())).thenAnswer(
      (_) async => [
        (projectId: 'active', completedAt: DateTime.now()),
        (projectId: 'inactive', completedAt: DateTime.now()),
      ],
    );
    when(
      () => insights.getOpenCountsByProject(),
    ).thenAnswer((_) async => {'active': 1});
    when(() => insights.getTrackingStart()).thenAnswer((_) async => null);

    final result = await container.read(historyInsightsProvider(range).future);

    expect(result.velocity.map((v) => v.projectId), ['active']);
    expect(result.trackingSince, isNull);
    expect(result.leadTimes, isNull);
    expect(result.slips, isNull);
    expect(result.planAccuracy, isNull);
    verifyNever(() => insights.getLeadTimeRows(any(), any()));
  });

  test(
    'builds tracked insights and clamps range to first completion',
    () async {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 3),
      );
      final first = DateTime(2026, 2);
      when(
        () => history.getFirstCompletedDate(),
      ).thenAnswer((_) async => first);
      when(
        () => insights.getCompletionsSince(any()),
      ).thenAnswer((_) async => []);
      when(() => insights.getOpenCountsByProject()).thenAnswer((_) async => {});
      when(
        () => insights.getTrackingStart(),
      ).thenAnswer((_) async => DateTime(2026, 1, 15));
      when(
        () => insights.getLeadTimeRows(first, range.end),
      ).thenAnswer((_) async => []);
      when(
        () => insights.getSlipRows(first, range.end),
      ).thenAnswer((_) async => []);
      when(
        () => insights.getScheduleTimelines(first, range.end),
      ).thenAnswer((_) async => <ScheduleTimeline>[]);

      final result = await container.read(
        historyInsightsProvider(range).future,
      );

      expect(result.trackingSince, DateTime(2026, 1, 15));
      expect(result.leadTimes, isNull);
      expect(result.slips, isNull);
      expect(result.planAccuracy, isNotNull);
      verify(() => insights.getLeadTimeRows(first, range.end)).called(1);
    },
  );
}
