import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class HistoryInsightsRepository implements IHistoryInsightsRepository {
  final Database _db;

  HistoryInsightsRepository(this._db);

  @override
  Future<List<Completion>> getCompletionsSince(DateTime since) async {
    final rows = await _db.query(
      'tasks',
      columns: ['projectId', 'completedAt'],
      where: 'status = ? AND completedAt >= ?',
      whereArgs: [TaskStatus.done.index, since.toIso8601String()],
    );
    return [
      for (final r in rows)
        (
          projectId: r['projectId'] as String?,
          completedAt: DateTime.parse(r['completedAt']! as String),
        ),
    ];
  }

  @override
  Future<Map<String, int>> getOpenCountsByProject() async {
    final rows = await _db.rawQuery(
      'SELECT projectId, COUNT(*) AS count FROM tasks '
      'WHERE status != ? AND projectId IS NOT NULL GROUP BY projectId',
      [TaskStatus.done.index],
    );
    return {
      for (final r in rows)
        r['projectId']! as String: (r['count']! as num).toInt(),
    };
  }

  @override
  Future<DateTime?> getTrackingStart() async {
    final rows = await _db.rawQuery('SELECT MIN(at) AS at FROM task_events');
    final at = rows.first['at'] as String?;
    return at == null ? null : DateTime.parse(at);
  }

  @override
  Future<List<LeadTimeRow>> getLeadTimeRows(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT t.projectId, t.createdAt, t.completedAt,
        (SELECT MIN(e.at) FROM task_events e
          WHERE e.taskId = t.id AND e.type = 'schedule' AND e.toValue IS NOT NULL
        ) AS firstScheduledAt
      FROM tasks t
      WHERE t.status = ? AND t.completedAt >= ? AND t.completedAt <= ?
      ''',
      [TaskStatus.done.index, start.toIso8601String(), end.toIso8601String()],
    );
    return [
      for (final r in rows)
        (
          projectId: r['projectId'] as String?,
          createdAt: DateTime.parse(r['createdAt']! as String),
          completedAt: DateTime.parse(r['completedAt']! as String),
          firstScheduledAt: r['firstScheduledAt'] == null
              ? null
              : DateTime.parse(r['firstScheduledAt']! as String),
        ),
    ];
  }

  @override
  Future<List<SlipRow>> getSlipRows(DateTime start, DateTime end) async {
    final rows = await _db.rawQuery(
      '''
      SELECT t.id, t.title,
        SUM(CASE WHEN e.fromValue IS NOT NULL AND e.toValue IS NOT NULL
            THEN 1 ELSE 0 END) AS moves
      FROM tasks t
      JOIN task_events e ON e.taskId = t.id AND e.type = 'schedule'
      WHERE t.status = ? AND t.completedAt >= ? AND t.completedAt <= ?
      GROUP BY t.id
      ''',
      [TaskStatus.done.index, start.toIso8601String(), end.toIso8601String()],
    );
    return [
      for (final r in rows)
        (
          id: r['id']! as String,
          title: r['title']! as String,
          moves: (r['moves']! as num).toInt(),
        ),
    ];
  }

  @override
  Future<List<ScheduleTimeline>> getScheduleTimelines(
    DateTime start,
    DateTime end,
  ) async {
    final from = start.normalize.toIso8601String();
    final to = end.normalize.toIso8601String();
    final tasks = await _db.rawQuery(
      '''
      SELECT id, scheduledDate, completedAt FROM tasks
      WHERE (scheduledDate >= ? AND scheduledDate <= ?)
        OR id IN (SELECT taskId FROM task_events WHERE type = 'schedule'
          AND ((toValue >= ? AND toValue <= ?) OR (fromValue >= ? AND fromValue <= ?)))
      ''',
      [from, to, from, to, from, to],
    );
    final events = await _db.query(
      'task_events',
      where: "type = 'schedule'",
      orderBy: 'at ASC, rowid ASC',
    );
    final byTask = <String, List<ScheduleEvent>>{};
    for (final e in events) {
      (byTask[e['taskId']! as String] ??= []).add(
        ScheduleEvent(
          at: DateTime.parse(e['at']! as String),
          from: _parse(e['fromValue']),
          to: _parse(e['toValue']),
        ),
      );
    }
    return [
      for (final t in tasks)
        ScheduleTimeline(
          current: _parse(t['scheduledDate']),
          completedAt: _parse(t['completedAt']),
          events: byTask[t['id']! as String] ?? const [],
        ),
    ];
  }

  DateTime? _parse(Object? v) => v == null ? null : DateTime.parse(v as String);
}
