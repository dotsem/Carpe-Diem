import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Attaches label and tag ids to task rows with one query per relation.
Future<List<Task>> loadTasksWithRelations(
  DatabaseExecutor db,
  List<Map<String, dynamic>> maps,
) async {
  if (maps.isEmpty) return [];

  final taskIds = maps.map((m) => m['id'] as String).toList();
  final placeholders = taskIds.map((_) => '?').join(',');

  final labelsData = await db.rawQuery(
    'SELECT taskId, labelId FROM task_labels WHERE taskId IN ($placeholders)',
    taskIds,
  );

  final labelMap = <String, List<String>>{};
  for (final row in labelsData) {
    final tId = row['taskId']! as String;
    final lId = row['labelId']! as String;
    labelMap.putIfAbsent(tId, () => []).add(lId);
  }

  final tagsData = await db.rawQuery(
    'SELECT taskId, tagId FROM task_tags WHERE taskId IN ($placeholders)',
    taskIds,
  );

  final tagMap = <String, List<String>>{};
  for (final row in tagsData) {
    final tId = row['taskId']! as String;
    final tgId = row['tagId']! as String;
    tagMap.putIfAbsent(tId, () => []).add(tgId);
  }

  return maps
      .map(
        (m) => Task.fromMap(
          m,
          labelIds: labelMap[m['id']] ?? const [],
          tagIds: tagMap[m['id']] ?? const [],
        ),
      )
      .toList();
}
