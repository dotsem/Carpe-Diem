import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history models aggregate and expose their values', () {
    final plan = PlanAccuracy({
      DateTime(2026): (scheduled: 3, done: 2),
      DateTime(2026, 1, 2): (scheduled: 1, done: 1),
    });
    expect(plan.scheduled, 4);
    expect(plan.done, 3);
    expect(HistoryOverview.empty().totalCompleted, 0);
    expect(
      ProjectHistorySummary(
        projectId: null,
        projectName: 'None',
        taskCount: 1,
        color: 0,
      ).taskCount,
      1,
    );

    final event = ScheduleEvent(at: DateTime(2026));
    expect(event.at, DateTime(2026));
    expect(const ScheduleTimeline().events, isEmpty);
    expect(
      const LeadTimeStats(
        medianIncubationDays: 1,
        medianExecutionDays: 2,
        sample: 3,
        slowestProjects: [],
      ).sample,
      3,
    );
    expect(const SlipStats(movesPerTask: 1, topTasks: []).movesPerTask, 1);
    expect(
      ProjectVelocity(
        projectId: 'p',
        usualPerWeek: 1,
        recentPerWeek: 2,
        delta: 1,
        isNew: false,
        lastCompletedAt: DateTime(2026),
      ).projectId,
      'p',
    );
    expect(
      CompletionGap(
        start: DateTime(2026),
        end: DateTime(2026, 1, 2),
        days: 1,
      ).days,
      1,
    );
    expect(const HistoryInsights(velocity: []).velocity, isEmpty);
    expect(
      ActivityData(
        dailyCounts: const {},
        start: DateTime(2026),
        end: DateTime(2026),
      ).dailyCounts,
      isEmpty,
    );
  });
}
