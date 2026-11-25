import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<bool> _exists(DatabaseExecutor txn, String table, String id) async =>
    (await txn.rawQuery('SELECT 1 FROM $table WHERE id = ?', [id])).isNotEmpty;

/// Nulls the project, blocker and parent references in [map] that point at rows
/// that no longer exist, so the insert or update cannot violate a foreign key.
Future<void> nullMissingRefs(
  DatabaseExecutor txn,
  Task task,
  Map<String, dynamic> map,
) async {
  final projectId = task.projectId;
  if (projectId != null && !await _exists(txn, 'projects', projectId)) {
    map['projectId'] = null;
  }
  final blockedById = task.blockedById;
  if (blockedById != null && !await _exists(txn, 'tasks', blockedById)) {
    map['blockedById'] = null;
  }
  final parentId = task.parentId;
  if (parentId != null &&
      (parentId == task.id || !await _exists(txn, 'tasks', parentId))) {
    map['parentId'] = null;
  }
}

/// Replaces the label and tag links of [task], skipping ids that no longer exist.
Future<void> replaceTaskRelations(DatabaseExecutor txn, Task task) async {
  await _replace(
    txn,
    task.id,
    'task_labels',
    'labelId',
    'labels',
    task.labelIds,
  );
  await _replace(txn, task.id, 'task_tags', 'tagId', 'tags', task.tagIds);
}

Future<void> _replace(
  DatabaseExecutor txn,
  String taskId,
  String linkTable,
  String column,
  String targetTable,
  List<String> ids,
) async {
  await txn.delete(linkTable, where: 'taskId = ?', whereArgs: [taskId]);
  for (final id in ids) {
    if (await _exists(txn, targetTable, id)) {
      await txn.insert(linkTable, {'taskId': taskId, column: id});
    }
  }
}
