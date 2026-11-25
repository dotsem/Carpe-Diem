import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_event_logger.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_order_sql.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_relations_loader.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_relations_writer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TaskRepository extends ITaskRepository {
  final Database _db;

  static const _baseSelect = '''
    SELECT DISTINCT t.*, blocker.title AS blockerTitle, blocker.status AS blockerStatus
    FROM tasks t
    LEFT JOIN tasks blocker ON t.blockedById = blocker.id
  ''';

  TaskRepository(this._db);

  @override
  Future<List<Task>> getAll({
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final maps = await _db.rawQuery('''
      $_baseSelect
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE p.isActive IS NULL OR p.isActive = 1
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue)}
    ''');
    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<Task?> getById(String id) async {
    final maps = await _db.rawQuery('$_baseSelect WHERE t.id = ?', [id]);
    if (maps.isEmpty) return null;

    return (await loadTasksWithRelations(_db, maps)).first;
  }

  @override
  Future<List<Task>> getByBlockedBy(String taskId) async {
    final maps = await _db.rawQuery('$_baseSelect WHERE t.blockedById = ?', [
      taskId,
    ]);
    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getByParent(String parentId) async {
    final maps = await _db.rawQuery(
      '$_baseSelect WHERE t.parentId = ? ORDER BY ${taskOrderBy(tableAlias: 't')}',
      [parentId],
    );
    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getByDate(
    DateTime date, {
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final scheduledDateStr = startOfDay.toIso8601String();

    final maps = await _db.rawQuery(
      '''
      $_baseSelect
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE ((date(t.scheduledDate) = date(?)) OR (t.completedAt >= ? AND t.completedAt < ?))
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue, today: startOfDay, isPlanOrder: true)}
    ''',
      [
        scheduledDateStr,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getOverdue(DateTime today) async {
    final dateStr = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final maps = await _db.rawQuery(
      '''
      $_baseSelect
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE (t.scheduledDate IS NOT NULL AND t.scheduledDate < ? AND t.status != ?)
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY t.isUrgent DESC, t.scheduledDate ASC
    ''',
      [dateStr, TaskStatus.done.index],
    );

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getUnscheduled({
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final maps = await _db.rawQuery('''
      $_baseSelect
      LEFT JOIN projects p ON t.projectId = p.id
      WHERE t.scheduledDate IS NULL
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue)}
    ''');

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getByProject(
    String projectId, {
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final maps = await _db.rawQuery(
      '''
      $_baseSelect
      WHERE t.projectId = ?
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue)}
    ''',
      [projectId],
    );

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getByProjectUnscheduled(
    String projectId, {
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final maps = await _db.rawQuery(
      '''
      $_baseSelect
      WHERE t.projectId = ? AND t.scheduledDate IS NULL
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue)}
    ''',
      [projectId],
    );

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<List<Task>> getByLabel(
    String labelId, {
    bool prioritizeDeadlines = true,
    bool prioritizeOverdue = false,
  }) async {
    final maps = await _db.rawQuery(
      '''
      $_baseSelect
      LEFT JOIN projects p ON t.projectId = p.id
      LEFT JOIN project_labels pl ON t.projectId = pl.projectId
      LEFT JOIN task_labels tl ON t.id = tl.taskId
      WHERE (pl.labelId = ? OR tl.labelId = ?)
      AND (p.isActive IS NULL OR p.isActive = 1)
      ORDER BY ${taskOrderBy(tableAlias: 't', prioritizeDeadlines: prioritizeDeadlines, prioritizeOverdue: prioritizeOverdue)}
    ''',
      [labelId, labelId],
    );

    return await loadTasksWithRelations(_db, maps);
  }

  @override
  Future<void> insert(Task task) async {
    await _db.transaction((txn) async {
      final map = task.toMap();
      map['updatedAt'] ??= task.createdAt.toIso8601String();
      await nullMissingRefs(txn, task, map);
      await txn.insert('tasks', map);
      await TaskEventLogger.logInsert(txn, task.id, map);
      await replaceTaskRelations(txn, task);
    });
  }

  @override
  Future<void> update(Task task) async {
    await _db.transaction((txn) async {
      await _update(txn, task);
    });
  }

  @override
  Future<void> updateAll(List<Task> tasks) async {
    await _db.transaction((txn) async {
      for (final task in tasks) {
        await _update(txn, task);
      }
    });
  }

  Future<void> _update(DatabaseExecutor txn, Task task) async {
    final map = task.toMap();
    map.remove('id');
    map['updatedAt'] = DateTime.now().toIso8601String();
    await nullMissingRefs(txn, task, map);
    final oldRow = (await txn.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [task.id],
    )).firstOrNull;
    if (oldRow == null) return;
    await txn.update('tasks', map, where: 'id = ?', whereArgs: [task.id]);
    await TaskEventLogger.logUpdate(txn, task.id, oldRow, map);
    await replaceTaskRelations(txn, task);
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> cleanupHistory(int days) async {
    final threshold = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    return await _db.delete(
      'tasks',
      where: 'status = ? AND completedAt < ?',
      whereArgs: [TaskStatus.done.index, threshold],
    );
  }
}
