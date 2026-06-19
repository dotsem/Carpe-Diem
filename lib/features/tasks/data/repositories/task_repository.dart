import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class TaskRepository extends ITaskRepository {
  final Database _db;

  TaskRepository(this._db);

  Future<List<Task>> _loadTasksWithLabels(List<Map<String, dynamic>> maps) async {
    if (maps.isEmpty) return [];

    final taskIds = maps.map((m) => m['id'] as String).toList();

    final labelsData = await _db.rawQuery(
      'SELECT taskId, labelId FROM task_labels WHERE taskId IN (${taskIds.map((_) => "?").join(",")})',
      taskIds,
    );

    final Map<String, List<String>> labelMap = {};
    for (final row in labelsData) {
      final tId = row['taskId'] as String;
      final lId = row['labelId'] as String;
      labelMap.putIfAbsent(tId, () => []).add(lId);
    }

    return maps.map((m) => Task.fromMap(m, labelIds: labelMap[m['id']] ?? const [])).toList();
  }

  @override
  Future<List<Task>> getAll({bool prioritizeDeadlines = true}) async {
    final maps = await _db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE p.isActive IS NULL OR p.isActive = 1
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''');
    return _loadTasksWithLabels(maps);
  }

  @override
  Future<Task?> getById(String id) async {
    final maps = await _db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final labelIds = await _getLabelIds(id);
    return Task.fromMap(maps.first, labelIds: labelIds);
  }

  @override
  Future<List<Task>> getByBlockedBy(String taskId) async {
    final maps = await _db.query('tasks', where: 'blockedById = ?', whereArgs: [taskId]);
    return _loadTasksWithLabels(maps);
  }

  @override
  Future<List<Task>> getByDate(DateTime date, {bool prioritizeDeadlines = true}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final scheduledDateStr = startOfDay.toIso8601String();

    final maps = await _db.rawQuery(
      '''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE ((t.scheduledDate = ?) OR (t.completedAt >= ? AND t.completedAt < ?))
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''',
      [scheduledDateStr, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return _loadTasksWithLabels(maps);
  }

  @override
  Future<List<Task>> getOverdue(DateTime today) async {
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final maps = await _db.rawQuery(
      '''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE (t.scheduledDate IS NOT NULL AND t.scheduledDate < ? AND t.status != ?)
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY t.priority DESC, t.scheduledDate ASC
    ''',
      [dateStr, TaskStatus.done.index],
    );

    return _loadTasksWithLabels(maps);
  }

  @override
  Future<List<Task>> getUnscheduled({bool prioritizeDeadlines = true}) async {
    final maps = await _db.rawQuery('''
      SELECT DISTINCT t.* FROM tasks t
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE t.scheduledDate IS NULL
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${_getOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines)}
    ''');

    return _loadTasksWithLabels(maps);
  }

  @override
  Future<List<Task>> getByProject(String projectId, {bool prioritizeDeadlines = true}) async {
    final maps = await _db.query(
      'tasks',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: _getOrderBy(useScheduledDate: true, prioritizeDeadlines: prioritizeDeadlines),
    );

    return _loadTasksWithLabels(maps);
  }

  @override
  Future<List<Task>> getByLabel(String labelId, {bool prioritizeDeadlines = true}) async {
    final maps = await _db.rawQuery(
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

    return _loadTasksWithLabels(maps);
  }

  @override
  Future<void> insert(Task task) async {
    await _db.transaction((txn) async {
      await txn.insert('tasks', task.toMap());
      for (final labelId in task.labelIds) {
        await txn.insert('task_labels', {'taskId': task.id, 'labelId': labelId});
      }
    });
  }

  @override
  Future<void> update(Task task) async {
    await _db.transaction((txn) async {
      await txn.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);

      await txn.delete('task_labels', where: 'taskId = ?', whereArgs: [task.id]);
      for (final labelId in task.labelIds) {
        await txn.insert('task_labels', {'taskId': task.id, 'labelId': labelId});
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> cleanupHistory(int days) async {
    final threshold = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await _db.delete(
      'tasks',
      where: 'status = ? AND completedAt < ?',
      whereArgs: [TaskStatus.done.index, threshold],
    );
  }

  Future<List<String>> _getLabelIds(String taskId) async {
    final maps = await _db.query('task_labels', where: 'taskId = ?', columns: ['labelId'], whereArgs: [taskId]);
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
}
