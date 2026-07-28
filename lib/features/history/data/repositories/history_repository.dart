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

    final where = StringBuffer(
      't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?',
    );
    final List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    if (filter != null) {
      _applyFilterToWhereClause(filter, where, whereArgs);
    }

    final query =
        '''
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
      final tagIds = await _getTagIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds, tagIds: tagIds));
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
  Future<HistoryOverview> getHistoryOverview(
    DateTime start,
    DateTime end, {
    TaskFilter? filter,
  }) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final where = StringBuffer(
      't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?',
    );
    final List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    final whereCreated = StringBuffer('t.createdAt >= ? AND t.createdAt <= ?');
    final List<dynamic> whereCreatedArgs = [startStr, endStr];

    if (filter != null) {
      _applyFilterToWhereClause(filter, where, whereArgs);
      _applyFilterToWhereClause(filter, whereCreated, whereCreatedArgs);
    }

    // 1. Total Completed
    final totalCompletedResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $where',
      whereArgs,
    );
    final totalCompleted =
        (totalCompletedResult.first['count'] as num?)?.toInt() ?? 0;

    // 2. Missed Deadlines
    final missedDeadlinesResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $where AND t.deadline IS NOT NULL AND t.completedAt > t.deadline',
      whereArgs,
    );
    final missedDeadlines =
        (missedDeadlinesResult.first['count'] as num?)?.toInt() ?? 0;

    // 3. Completed Late (after scheduled date)
    final completedLateResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $where AND t.scheduledDate IS NOT NULL AND t.completedAt > datetime(t.scheduledDate, \'+1 day\')',
      whereArgs,
    );
    final completedLate =
        (completedLateResult.first['count'] as num?)?.toInt() ?? 0;

    // 4. Total Created in this period
    final totalCreatedResult = await _db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t WHERE $whereCreated',
      whereCreatedArgs,
    );
    final totalCreated =
        (totalCreatedResult.first['count'] as num?)?.toInt() ?? 0;

    // 5. Tasks by Project
    final projectsResult = await _db.rawQuery(
      'SELECT t.projectId, COUNT(DISTINCT t.id) as count FROM tasks t WHERE $where GROUP BY t.projectId',
      whereArgs,
    );
    final tasksByProject = {
      for (var r in projectsResult)
        (r['projectId'] as String? ?? 'none'): r['count'] as int,
    };

    // 6. Tasks by Label
    final labelsResult = await _db.rawQuery('''
      SELECT tl.labelId, COUNT(DISTINCT t.id) as count 
      FROM tasks t 
      JOIN task_labels tl ON t.id = tl.taskId 
      WHERE $where 
      GROUP BY tl.labelId
      ''', whereArgs);
    final tasksByLabel = {
      for (var r in labelsResult) r['labelId'] as String: r['count'] as int,
    };

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
    final maps = await _db.query(
      'task_labels',
      where: 'taskId = ?',
      columns: ['labelId'],
      whereArgs: [taskId],
    );
    return maps.map((m) => m['labelId'] as String).toList();
  }

  Future<List<String>> _getTagIds(String taskId) async {
    final maps = await _db.query(
      'task_tags',
      where: 'taskId = ?',
      columns: ['tagId'],
      whereArgs: [taskId],
    );
    return maps.map((m) => m['tagId'] as String).toList();
  }

  void _applyFilterToWhereClause(
    TaskFilter filter,
    StringBuffer where,
    List<dynamic> whereArgs,
  ) {
    if (filter.isEmpty) return;

    if (filter.isUrgent == true) {
      where.write(' AND t.isUrgent = 1');
    }
    if (filter.isUrgent == false) {
      where.write(' AND t.isUrgent = 0');
    }
    if (filter.projectIdsIncluded.isNotEmpty) {
      final p = List.filled(filter.projectIdsIncluded.length, '?').join(',');
      where.write(' AND t.projectId IN ($p)');
      whereArgs.addAll(filter.projectIdsIncluded);
    }
    if (filter.projectIdsExcluded.isNotEmpty) {
      final p = List.filled(filter.projectIdsExcluded.length, '?').join(',');
      where.write(' AND (t.projectId IS NULL OR t.projectId NOT IN ($p))');
      whereArgs.addAll(filter.projectIdsExcluded);
    }
    if (filter.labelIdsIncluded.isNotEmpty) {
      final p = List.filled(filter.labelIdsIncluded.length, '?').join(',');
      where.write(
        ' AND (t.id IN (SELECT taskId FROM task_labels WHERE labelId IN ($p)) OR t.projectId IN (SELECT projectId FROM project_labels WHERE labelId IN ($p)))',
      );
      whereArgs.addAll(filter.labelIdsIncluded);
      whereArgs.addAll(filter.labelIdsIncluded);
    }
    if (filter.labelIdsExcluded.isNotEmpty) {
      final p = List.filled(filter.labelIdsExcluded.length, '?').join(',');
      where.write(
        ' AND t.id NOT IN (SELECT taskId FROM task_labels WHERE labelId IN ($p)) AND (t.projectId IS NULL OR t.projectId NOT IN (SELECT projectId FROM project_labels WHERE labelId IN ($p)))',
      );
      whereArgs.addAll(filter.labelIdsExcluded);
      whereArgs.addAll(filter.labelIdsExcluded);
    }
    if (filter.tagIdsIncluded.isNotEmpty) {
      final p = List.filled(filter.tagIdsIncluded.length, '?').join(',');
      where.write(
        ' AND t.id IN (SELECT taskId FROM task_tags WHERE tagId IN ($p))',
      );
      whereArgs.addAll(filter.tagIdsIncluded);
    }
    if (filter.tagIdsExcluded.isNotEmpty) {
      final p = List.filled(filter.tagIdsExcluded.length, '?').join(',');
      where.write(
        ' AND t.id NOT IN (SELECT taskId FROM task_tags WHERE tagId IN ($p))',
      );
      whereArgs.addAll(filter.tagIdsExcluded);
    }
  }
}
