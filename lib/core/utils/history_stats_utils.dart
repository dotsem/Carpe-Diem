import 'dart:math';

import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';

const velocityBaselineDays = 56;
const velocityRecentDays = 7;

/// Projects that completed fewer tasks than their own usual pace.
///
/// Usual pace is completions per day over the 56 days before the last 7. It
/// is always divided by the full 56 days, so a project with one old task has
/// a tiny pace and never ranks. The window is the last 7 days, or the time
/// since the last completion when that is longer. Score is expected minus
/// actual completions in that window, so lost volume ranks above lost
/// percentage. Projects with no open tasks or a shortfall under 1 are dropped.
List<ProjectVelocity> projectVelocity(
  Iterable<Completion> completions,
  Map<String, int> openCounts, {
  required DateTime now,
}) {
  final recentStart = now.subtract(const Duration(days: velocityRecentDays));
  final baselineStart = recentStart.subtract(
    const Duration(days: velocityBaselineDays),
  );

  final byProject = <String, List<DateTime>>{};
  for (final c in completions) {
    final id = c.projectId;
    if (id == null || (openCounts[id] ?? 0) == 0) continue;
    (byProject[id] ??= []).add(c.completedAt);
  }

  final result = <ProjectVelocity>[];
  byProject.forEach((id, dates) {
    final last = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final baseline = dates
        .where((d) => !d.isBefore(baselineStart) && d.isBefore(recentStart))
        .length;
    final recent = dates.where((d) => !d.isBefore(recentStart)).length;

    final perDay = baseline / velocityBaselineDays;
    final windowDays = max(
      velocityRecentDays.toDouble(),
      last.fractionalDaysUntil(now),
    );
    final shortfall = perDay * windowDays - recent;
    if (shortfall < 1) return;

    result.add(
      ProjectVelocity(
        projectId: id,
        usualPerWeek: perDay * 7,
        recentPerWeek: recent / windowDays * 7,
        shortfall: shortfall,
        lastCompletedAt: last,
      ),
    );
  });

  result.sort((a, b) => b.shortfall.compareTo(a.shortfall));
  return result;
}

/// Completions per calendar day, keyed by midnight.
Map<DateTime, int> dailyCounts(Iterable<DateTime> completions) {
  final counts = <DateTime, int>{};
  for (final d in completions) {
    counts.update(d.normalize, (v) => v + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// Period shown by the activity heatmap: the last 12 months for a null
/// [year], otherwise that calendar year, ending today for the current year.
/// The start is clamped to [firstCompleted] so days before the first ever
/// completion never read as a vacation.
({DateTime start, DateTime end}) activityWindow(
  int? year, {
  required DateTime now,
  DateTime? firstCompleted,
}) {
  var start = year == null
      ? DateTime(now.year - 1, now.month, now.day + 1)
      : DateTime(year);
  final end = year == null || year == now.year
      ? now.normalize
      : DateTime(year, 12, 31);
  final first = firstCompleted?.normalize;
  if (first != null && first.isAfter(start)) start = first;
  return (start: start, end: end);
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Median days from created to first scheduled (incubation, informational)
/// and from first scheduled to done (execution, the real speed measure).
/// Tasks without a schedule event are unknown and skipped. Projects need 3
/// tracked tasks to appear in the slowest list.
LeadTimeStats? leadTimes(Iterable<LeadTimeRow> rows) {
  final tracked = rows.where((r) => r.firstScheduledAt != null).toList();
  if (tracked.isEmpty) return null;

  final byProject = <String, List<double>>{};
  for (final r in tracked) {
    final id = r.projectId;
    if (id != null) {
      (byProject[id] ??= []).add(
        r.firstScheduledAt!.fractionalDaysUntil(r.completedAt),
      );
    }
  }
  final slowest = [
    for (final e in byProject.entries)
      if (e.value.length >= 3) (projectId: e.key, days: _median(e.value)!),
  ]..sort((a, b) => b.days.compareTo(a.days));

  return LeadTimeStats(
    medianIncubationDays: _median([
      for (final r in tracked)
        r.createdAt.fractionalDaysUntil(r.firstScheduledAt!),
    ])!,
    medianExecutionDays: _median([
      for (final r in tracked)
        r.firstScheduledAt!.fractionalDaysUntil(r.completedAt),
    ])!,
    sample: tracked.length,
    slowestProjects: slowest.take(3).toList(),
  );
}

/// Reschedules per completed tracked task, plus the 5 most moved tasks.
/// Scheduling from or to the backlog is not a move.
SlipStats? slipStats(List<SlipRow> rows) {
  if (rows.isEmpty) return null;
  final moved = rows.where((r) => r.moves > 0).toList()
    ..sort((a, b) => b.moves.compareTo(a.moves));
  return SlipStats(
    movesPerTask: rows.fold(0, (a, r) => a + r.moves) / rows.length,
    topTasks: moved.take(5).toList(),
  );
}

/// Per day: tasks that were scheduled for that day at any point during it,
/// and how many of those were completed that day. Days before
/// [trackingSince] are skipped. Tasks without events were scheduled
/// throughout, since any change since tracking began would have logged one.
PlanAccuracy planAccuracy(
  Iterable<ScheduleTimeline> timelines, {
  required DateTime start,
  required DateTime end,
  required DateTime trackingSince,
}) {
  final first = trackingSince.normalize.isAfter(start.normalize)
      ? trackingSince.normalize
      : start.normalize;
  final last = end.normalize;
  final days = <DateTime, PlanDay>{};

  for (final t in timelines) {
    final segments = t.events.isEmpty
        ? [
            (
              value: t.current,
              from: null as DateTime?,
              until: null as DateTime?,
            ),
          ]
        : [
            (
              value: t.events.first.from,
              from: null as DateTime?,
              until: t.events.first.at as DateTime?,
            ),
            for (var i = 0; i < t.events.length; i++)
              (
                value: t.events[i].to,
                from: t.events[i].at as DateTime?,
                until: i + 1 < t.events.length ? t.events[i + 1].at : null,
              ),
          ];

    final counted = <DateTime>{};
    for (final s in segments) {
      final day = s.value?.normalize;
      if (day == null || day.isBefore(first) || day.isAfter(last)) continue;
      final dayEnd = DateTime(day.year, day.month, day.day + 1);
      final startsInTime = s.from == null || s.from!.isBefore(dayEnd);
      final endsInTime = s.until == null || s.until!.isAfter(day);
      if (startsInTime && endsInTime) counted.add(day);
    }
    for (final day in counted) {
      final prev = days[day] ?? (scheduled: 0, done: 0);
      final done = t.completedAt != null && t.completedAt!.normalize == day;
      days[day] = (
        scheduled: prev.scheduled + 1,
        done: prev.done + (done ? 1 : 0),
      );
    }
  }
  return PlanAccuracy(days);
}
