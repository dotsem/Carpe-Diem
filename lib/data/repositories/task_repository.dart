import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/data/database/database_helper.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/data/models/history_overview.dart';

class TaskRepository {
  Future<Database> get _db => DatabaseHelper.database;

  Future<List<Task>> getAll({bool prioritizeDeadlines = true}) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE p.isActive IS NULL OR p.isActive = 1
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''');

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<Task?> getById(String id) async {
    final db = await _db;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final labelIds = await _getLabelIds(id);
    return Task.fromMap(maps.first, labelIds: labelIds);
  }

  Future<List<Task>> getByBlockedBy(String taskId) async {
    final db = await _db;
    final maps = await db.query('tasks', where: 'blockedById = ?', whereArgs: [taskId]);
    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<List<Task>> getByDate(DateTime date, {bool prioritizeDeadlines = true}) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final scheduledDateStr = startOfDay.toIso8601String();

    final maps = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE ((t.scheduledDate = ?) OR (t.completedAt >= ? AND t.completedAt < ?))
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''', [scheduledDateStr, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<List<Task>> getOverdue(DateTime today) async {
    final db = await _db;
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final maps = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE (t.scheduledDate IS NOT NULL AND t.scheduledDate < ? AND t.status != ?)
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY t.priority DESC, t.scheduledDate ASC
    ''', [dateStr, TaskStatus.done.index]);

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<List<Task>> getUnscheduled({bool prioritizeDeadlines = true}) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE t.scheduledDate IS NULL
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''');

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<List<Task>> getByProject(String projectId, {bool prioritizeDeadlines = true}) async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: _getOrderBy(useScheduledDate: true, prioritizeDeadlines: prioritizeDeadlines),
    );

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<List<Task>> getByLabel(String labelId, {bool prioritizeDeadlines = true}) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      LEFT JOIN project_labels pl ON t.projectId = pl.projectId
      LEFT JOIN task_labels tl ON t.id = tl.taskId
      WHERE (pl.labelId = ? OR tl.labelId = ?)
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${_getOrderBy(useScheduledDate: true, tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''',
      [labelId, labelId],
    );

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<void> insert(Task task) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('tasks', task.toMap());
      for (final labelId in task.labelIds) {
        await txn.insert('task_labels', {'taskId': task.id, 'labelId': labelId});
      }
    });
  }

  Future<void> update(Task task) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);

      await txn.delete('task_labels', where: 'taskId = ?', whereArgs: [task.id]);
      for (final labelId in task.labelIds) {
        await txn.insert('task_labels', {'taskId': task.id, 'labelId': labelId});
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> cleanupHistory(int days) async {
    final db = await _db;
    final threshold = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await db.delete(
      'tasks',
      where: 'status = ? AND completedAt < ?',
      whereArgs: [TaskStatus.done.index, threshold],
    );
  }

  Future<List<Task>> getCompletedInRange(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
    TaskFilter? filter,
  }) async {
    final db = await _db;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    String where = 't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?';
    List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    if (filter != null && !filter.isEmpty) {
      if (filter.hasPriorityFilter) {
        where += ' AND t.priority IN (${filter.priorities.map((p) => p.index).join(',')})';
      }
      if (filter.hasProjectFilter) {
        where += ' AND t.projectId IN (${filter.projectIds.map((id) => "'$id'").join(',')})';
      }
      if (filter.hasLabelFilter) {
        where +=
            ' AND (tl.labelId IN (${filter.labelIds.map((id) => "'$id'").join(',')}) OR pl.labelId IN (${filter.labelIds.map((id) => "'$id'").join(',')}))';
      }
    }

    final query =
        '''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN task_labels tl ON t.id = tl.taskId
      LEFT JOIN project_labels pl ON t.projectId = pl.projectId
      WHERE $where
      ORDER BY t.completedAt DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final maps = await db.rawQuery(query, whereArgs);

    List<Task> tasks = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      tasks.add(Task.fromMap(map, labelIds: labelIds));
    }
    return tasks;
  }

  Future<DateTime?> getFirstCompletedDate() async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where: 'status = ? AND completedAt IS NOT NULL',
      whereArgs: [TaskStatus.done.index],
      orderBy: 'completedAt ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['completedAt'] as String);
  }

  Future<List<String>> _getLabelIds(String taskId) async {
    final db = await _db;
    final maps = await db.query('task_labels', where: 'taskId = ?', columns: ['labelId'], whereArgs: [taskId]);
    return maps.map((m) => m['labelId'] as String).toList();
  }

  String _getOrderBy({bool useScheduledDate = false, String? tableAlias, bool prioritizeDeadlines = true}) {
    final prefix = tableAlias != null ? '$tableAlias.' : '';
    final deadlinePart = '(${prefix}deadline IS NULL), ${prefix}deadline ASC';
    final priorityPart = '${prefix}priority DESC';
    final datePart = useScheduledDate ? '${prefix}scheduledDate ASC' : '${prefix}createdAt DESC';

    if (prioritizeDeadlines) {
      return '$deadlinePart, $priorityPart, $datePart';
    } else {
      return '$priorityPart, $datePart, $deadlinePart';
    }
  }

  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter}) async {
    final db = await _db;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    String whereCompleted = 't.status = ? AND t.completedAt >= ? AND t.completedAt <= ?';
    List<dynamic> whereArgs = [TaskStatus.done.index, startStr, endStr];

    String filterJoin = '';
    String filterWhere = '';
    if (filter != null && !filter.isEmpty) {
      filterJoin = '''
        LEFT JOIN task_labels ftl ON t.id = ftl.taskId
        LEFT JOIN project_labels fpl ON t.projectId = fpl.projectId
      ''';
      if (filter.hasPriorityFilter) {
        filterWhere += ' AND t.priority IN (${filter.priorities.map((p) => p.index).join(',')})';
      }
      if (filter.hasProjectFilter) {
        filterWhere += ' AND t.projectId IN (${filter.projectIds.map((id) => "'$id'").join(',')})';
      }
      if (filter.hasLabelFilter) {
        filterWhere +=
            ' AND (ftl.labelId IN (${filter.labelIds.map((id) => "'$id'").join(',')}) OR fpl.labelId IN (${filter.labelIds.map((id) => "'$id'").join(',')}))';
      }
    }

    whereCompleted += filterWhere;

    // 1. Total Completed
    final totalCompletedResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t $filterJoin WHERE $whereCompleted',
      whereArgs,
    );
    final totalCompleted = (totalCompletedResult.first['count'] as num?)?.toInt() ?? 0;

    // 2. Missed Deadlines
    final missedDeadlinesResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t $filterJoin WHERE $whereCompleted AND t.deadline IS NOT NULL AND t.completedAt > t.deadline',
      whereArgs,
    );
    final missedDeadlines = (missedDeadlinesResult.first['count'] as num?)?.toInt() ?? 0;

    // 3. Completed Late (after scheduled date)
    final completedLateResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t $filterJoin WHERE $whereCompleted AND t.scheduledDate IS NOT NULL AND t.completedAt > datetime(t.scheduledDate, \'+1 day\')',
      whereArgs,
    );
    final completedLate = (completedLateResult.first['count'] as num?)?.toInt() ?? 0;

    // 4. Total Created in this period
    final totalCreatedResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT t.id) as count FROM tasks t $filterJoin WHERE t.createdAt >= ? AND t.createdAt <= ? $filterWhere',
      [startStr, endStr],
    );
    final totalCreated = (totalCreatedResult.first['count'] as num?)?.toInt() ?? 0;

    // 5. Tasks by Project
    final projectsResult = await db.rawQuery(
      'SELECT t.projectId, COUNT(DISTINCT t.id) as count FROM tasks t $filterJoin WHERE $whereCompleted GROUP BY t.projectId',
      whereArgs,
    );
    final tasksByProject = {for (var r in projectsResult) (r['projectId'] as String? ?? 'none'): r['count'] as int};

    // 6. Tasks by Label
    final labelsResult = await db.rawQuery('''
      SELECT tl.labelId, COUNT(DISTINCT t.id) as count 
      FROM tasks t 
      JOIN task_labels tl ON t.id = tl.taskId 
      $filterJoin
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
}
