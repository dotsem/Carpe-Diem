import 'package:carpe_diem/core/utils/history_stats_utils.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 17, 12);

  List<Completion> spread(String id, int count, DateTime from, int days) => [
    for (var i = 0; i < count; i++)
      (
        projectId: id,
        completedAt: from.add(Duration(hours: i * 24 * days ~/ count)),
      ),
  ];

  group('projectVelocity', () {
    test('one task then weeks of nothing does not rank', () {
      final c = [
        (projectId: 'a', completedAt: now.subtract(const Duration(days: 21))),
      ];
      expect(projectVelocity(c, {'a': 2}, now: now), isEmpty);
    });

    test('a busy project that slowed down ranks by lost volume', () {
      final baseline = spread(
        'busy',
        168,
        now.subtract(const Duration(days: 63)),
        56,
      );
      final recent = spread(
        'busy',
        3,
        now.subtract(const Duration(days: 6)),
        6,
      );
      final result = projectVelocity(
        [...baseline, ...recent],
        {'busy': 5},
        now: now,
      );
      expect(result, hasLength(1));
      expect(result.first.shortfall, closeTo(18, 0.5));
      expect(result.first.usualPerWeek, closeTo(21, 0.5));
    });

    test('project with no open tasks is excluded', () {
      final baseline = spread(
        'done',
        168,
        now.subtract(const Duration(days: 63)),
        56,
      );
      expect(projectVelocity(baseline, {}, now: now), isEmpty);
    });

    test('longer idle stretch grows the window', () {
      final baseline = spread(
        'p',
        56,
        now.subtract(const Duration(days: 63)),
        40,
      );
      final result = projectVelocity(baseline, {'p': 1}, now: now);
      expect(result.single.recentPerWeek, 0);
      expect(result.single.shortfall, greaterThan(5));
    });

    test('sorts by shortfall and skips tasks without a project', () {
      final big = spread(
        'big',
        168,
        now.subtract(const Duration(days: 63)),
        56,
      );
      final small = spread(
        'small',
        56,
        now.subtract(const Duration(days: 63)),
        56,
      );
      final none = [
        (projectId: null, completedAt: now.subtract(const Duration(days: 30))),
      ];
      final result = projectVelocity(
        [...small, ...big, ...none],
        {'big': 1, 'small': 1},
        now: now,
      );
      expect(result.map((v) => v.projectId), ['big', 'small']);
    });
  });

  test('dailyCounts groups by calendar day', () {
    final counts = dailyCounts([
      DateTime(2026, 11, 1, 8),
      DateTime(2026, 11, 1, 20),
      DateTime(2026, 11, 2, 8),
    ]);
    expect(counts[DateTime(2026, 11, 1)], 2);
    expect(counts[DateTime(2026, 11, 2)], 1);
  });

  group('leadTimes', () {
    test('skips tasks without a schedule event and splits the two phases', () {
      final created = DateTime(2026, 9, 1);
      final scheduled = DateTime(2026, 11, 1);
      final done = DateTime(2026, 11, 4);
      final stats = leadTimes([
        (
          projectId: 'a',
          createdAt: created,
          completedAt: done,
          firstScheduledAt: scheduled,
        ),
        (
          projectId: 'a',
          createdAt: created,
          completedAt: done,
          firstScheduledAt: null,
        ),
      ]);
      expect(stats!.sample, 1);
      expect(stats.medianIncubationDays, 61);
      expect(stats.medianExecutionDays, 3);
    });

    test('returns null when nothing is tracked', () {
      expect(leadTimes([]), isNull);
    });
  });

  test('slipStats ignores tasks that never moved in the top list', () {
    final stats = slipStats([
      (id: '1', title: 'a', moves: 0),
      (id: '2', title: 'b', moves: 3),
    ]);
    expect(stats!.movesPerTask, 1.5);
    expect(stats.topTasks.map((t) => t.id), ['2']);
  });

  group('planAccuracy', () {
    final since = DateTime(2026, 11, 1);
    final d10 = DateTime(2026, 11, 10);
    final d11 = DateTime(2026, 11, 11);

    PlanAccuracy run(List<ScheduleTimeline> t) => planAccuracy(
      t,
      start: DateTime(2026, 11, 1),
      end: DateTime(2026, 11, 30),
      trackingSince: since,
    );

    test('task scheduled for D and moved away during D still counts', () {
      final result = run([
        ScheduleTimeline(
          current: d11,
          completedAt: DateTime(2026, 11, 11, 15),
          events: [
            ScheduleEvent(at: DateTime(2026, 11, 9), to: d10),
            ScheduleEvent(at: DateTime(2026, 11, 10, 14), from: d10, to: d11),
          ],
        ),
      ]);
      expect(result.days[d10], (scheduled: 1, done: 0));
      expect(result.days[d11], (scheduled: 1, done: 1));
    });

    test('task moved away before D does not count for D', () {
      final result = run([
        ScheduleTimeline(
          current: d11,
          events: [
            ScheduleEvent(at: DateTime(2026, 11, 8), to: d10),
            ScheduleEvent(at: DateTime(2026, 11, 9), from: d10, to: d11),
          ],
        ),
      ]);
      expect(result.days[d10], isNull);
      expect(result.days[d11], (scheduled: 1, done: 0));
    });

    test('task added to D during D counts', () {
      final result = run([
        ScheduleTimeline(
          current: d10,
          completedAt: DateTime(2026, 11, 10, 17),
          events: [ScheduleEvent(at: DateTime(2026, 11, 10, 16), to: d10)],
        ),
      ]);
      expect(result.days[d10], (scheduled: 1, done: 1));
    });

    test('task without events counts for its current date', () {
      final result = run([ScheduleTimeline(current: d10)]);
      expect(result.days[d10], (scheduled: 1, done: 0));
    });

    test('days before tracking began are skipped', () {
      final result = planAccuracy(
        [ScheduleTimeline(current: DateTime(2026, 10, 20))],
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 11, 30),
        trackingSince: since,
      );
      expect(result.days, isEmpty);
    });
  });

  group('activityWindow', () {
    final today = DateTime(2026, 11, 17, 15);

    test('null year is the last 12 months ending today', () {
      final w = activityWindow(null, now: today);
      expect(w.start, DateTime(2025, 11, 18));
      expect(w.end, DateTime(2026, 11, 17));
    });

    test('past year is the whole calendar year', () {
      final w = activityWindow(2025, now: today);
      expect(w.start, DateTime(2025));
      expect(w.end, DateTime(2025, 12, 31));
    });

    test('current year ends today', () {
      final w = activityWindow(2026, now: today);
      expect(w.start, DateTime(2026));
      expect(w.end, DateTime(2026, 11, 17));
    });

    test('start is clamped to the first completion', () {
      final w = activityWindow(
        null,
        now: today,
        firstCompleted: DateTime(2026, 3, 9, 14),
      );
      expect(w.start, DateTime(2026, 3, 9));
    });

    test('year before the first completion gives an empty window', () {
      final w = activityWindow(
        2024,
        now: today,
        firstCompleted: DateTime(2026, 3, 9),
      );
      expect(w.start.isAfter(w.end), isTrue);
    });
  });
}
