import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class HistoryRepository implements IHistoryRepository {
  final Database _db;

  HistoryRepository(this._db);

  @override
  Future<List<Task>> getCompletedInRange(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
    TaskFilter? filter,
  }) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    String where = 't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?';
    List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    if (filter != null && !filter.isEmpty) {
      if (filter.isUrgent == true) {
        where += ' AND t.isUrgent = 1';
      }
      if (filter.isUrgent == false) {
        where += ' AND t.isUrgent = 0';
      }
      if (filter.projectIdsIncluded.isNotEmpty) {
        where += ' AND t.projectId IN (${filter.projectIdsIncluded.map((id) => "'$id'").join(',')})';
      }
      if (filter.projectIdsExcluded.isNotEmpty) {
        where += ' AND (t.projectId IS NULL OR t.projectId NOT IN (${filter.projectIdsExcluded.map((id) => "'$id'").join(',')}))';
      }
      if (filter.labelIdsIncluded.isNotEmpty) {
        final labelList = filter.labelIdsIncluded.map((id) => "'$id'").join(',');
        where += ' AND (t.id IN (SELECT taskId FROM task_labels WHERE labelId IN ($labelList)) OR t.projectId IN (SELECT projectId FROM project_labels WHERE labelId IN ($labelList)))';
      }
      if (filter.labelIdsExcluded.isNotEmpty) {
        final labelList = filter.labelIdsExcluded.map((id) => "'$id'").join(',');
        where += ' AND t.id NOT IN (SELECT taskId FROM task_labels WHERE labelId IN ($labelList)) AND (t.projectId IS NULL OR t.projectId NOT IN (SELECT projectId FROM project_labels WHERE labelId IN ($labelList)))';
      }
    }

    final query = '''
      SELECT DISTINCT t.* FROM tasks t
      WHERE $where
      ORDER BY t.completedAt DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final maps = await _db.rawQuery(query, whereArgs);

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  @override
  Future<DateTime?> getFirstCompletedDate() async {
    final maps = await _db.query(
      'tasks',
      where: 'status = ? AND completedAt IS NOT NULL',
      whereArgs: [TaskStatus.done.index],
      orderBy: 'completedAt ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['completedAt'] as String);
  }

  @override
  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter}) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    String whereCompleted = 't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?';
    List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    String filterWhere = '';
    if (filter != null && !filter.isEmpty) {
      if (filter.isUrgent == true) {
        filterWhere += ' AND t.isUrgent = 1';
      }
      if (filter.isUrgent == false) {
        filterWhere += ' AND t.isUrgent = 0';
      }
      if (filter.projectIdsIncluded.isNotEmpty) {
        filterWhere += ' AND t.projectId IN (${filter.projectIdsIncluded.map((id) => "'$id'").join(',')})';
      }
      if (filter.projectIdsExcluded.isNotEmpty) {
        filterWhere += ' AND (t.projectId IS NULL OR t.projectId NOT IN (${filter.projectIdsExcluded.map((id) => "'$id'").join(',')}))';
      }
      if (filter.labelIdsIncluded.isNotEmpty) {
        final labelList = filter.labelIdsIncluded.map((id) => "'$id'").join(',');
        filterWhere += ' AND (t.id IN (SELECT taskId FROM task_labels WHERE labelId IN ($labelList)) OR t.projectId IN (SELECT projectId FROM project_labels WHERE labelId IN ($labelList)))';
      }
      if (filter.labelIdsExcluded.isNotEmpty) {
        final labelList = filter.labelIdsExcluded.map((id) => "'$id'").join(',');
        filterWhere += ' AND t.id NOT IN (SELECT taskId FROM task_labels WHERE labelId IN ($labelList)) AND (t.projectId IS NULL OR t.projectId NOT IN (SELECT projectId FROM project_labels WHERE labelId IN ($labelList)))';
      }
    }

    whereCompleted += filterWhere;

    // 1. Total Completed
    final totalCompletedResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $whereCompleted',
      whereArgs,
    );
    final totalCompleted = (totalCompletedResult.first['count'] as num?)?.toInt() ?? 0;

    // 2. Missed Deadlines
    final missedDeadlinesResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $whereCompleted AND t.deadline IS NOT NULL AND t.completedAt > t.deadline',
      whereArgs,
    );
    final missedDeadlines = (missedDeadlinesResult.first['count'] as num?)?.toInt() ?? 0;

    // 3. Completed Late (after scheduled date)
    final completedLateResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $whereCompleted AND t.scheduledDate IS NOT NULL AND t.completedAt > datetime(t.scheduledDate, \'+1 day\')',
      whereArgs,
    );
    final completedLate = (completedLateResult.first['count'] as num?)?.toInt() ?? 0;

    // 4. Total Created in this period
    final totalCreatedResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE t.createdAt >= ? AND t.createdAt <= ? $filterWhere',
      [startStr, endStr],
    );
    final totalCreated = (totalCreatedResult.first['count'] as num?)?.toInt() ?? 0;

    // 5. Tasks by Project
    final projectsResult = await _db.rawQuery(
      'SELECT t.projectId, COUNT(DISTINCT t.id) as count FROM tasks t WHERE $whereCompleted GROUP BY t.projectId',
      whereArgs,
    );
    final tasksByProject = {for (var r in projectsResult) (r['projectId'] as String? ?? 'none'): r['count'] as int};

    // 6. Tasks by Label
    final labelsResult = await _db.rawQuery('''
      SELECT tl.labelId, COUNT(DISTINCT t.id) as count 
      FROM tasks t 
      JOIN task_labels tl ON t.id = tl.taskId 
      WHERE $whereCompleted 
      GROUP BY tl.labelId
      ''', whereArgs);
    final tasksByLabel = {for (var r in labelsResult) r['labelId'] as String: r['count'] as int};

    return HistoryOverview(
      totalCompleted: totalCompleted,
      totalCreated: totalCreated,
      missedDeadlines: missedDeadlines,
      completedLate: completedLate,
      tasksByProject: tasksByProject,
      tasksByLabel: tasksByLabel,
    );
  }

  Future<List<String>> _getLabelIds(String taskId) async {
    final maps = await _db.query('task_labels', where: 'taskId = ?', columns: ['labelId'], whereArgs: [taskId]);
    return maps.map((m) => m['labelId'] as String).toList();
  }
}

