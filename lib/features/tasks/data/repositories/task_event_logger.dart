import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Append-only log of schedule, status and project changes per task.
class TaskEventLogger {
  static const _uuid = Uuid();
  static const _fields = {
    'schedule': 'scheduledDate',
    'status': 'status',
    'project': 'projectId',
  };

  /// [row] is the map written to the tasks table.
  static Future<void> logInsert(
    DatabaseExecutor txn,
    String taskId,
    Map<String, Object?> row,
  ) async {
    final date = row['scheduledDate']?.toString();
    if (date != null) await _record(txn, taskId, 'schedule', null, date);
  }

  /// [oldRow] is the tasks row before the update, [newRow] the map written.
  static Future<void> logUpdate(
    DatabaseExecutor txn,
    String taskId,
    Map<String, Object?> oldRow,
    Map<String, Object?> newRow,
  ) async {
    for (final entry in _fields.entries) {
      final from = oldRow[entry.value]?.toString();
      final to = newRow[entry.value]?.toString();
      if (from != to) await _record(txn, taskId, entry.key, from, to);
    }
  }

  // why: undo/redo is generic and calls update(previous), so a change that
  // exactly reverses the latest event cancels it instead of adding a new one.
  static Future<void> _record(
    DatabaseExecutor txn,
    String taskId,
    String type,
    String? from,
    String? to,
  ) async {
    final latest = await txn.query(
      'task_events',
      where: 'taskId = ? AND type = ?',
      whereArgs: [taskId, type],
      orderBy: 'at DESC, rowid DESC',
      limit: 1,
    );
    if (latest.isNotEmpty &&
        latest.first['fromValue'] == to &&
        latest.first['toValue'] == from) {
      await txn.delete(
        'task_events',
        where: 'id = ?',
        whereArgs: [latest.first['id']],
      );
      return;
    }
    await txn.insert('task_events', {
      'id': _uuid.v4(),
      'taskId': taskId,
      'type': type,
      'at': DateTime.now().toIso8601String(),
      'fromValue': from,
      'toValue': to,
    });
  }
}
