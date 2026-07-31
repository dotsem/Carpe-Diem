// ignore_for_file: file_names, camel_case_types
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../migration.dart';

class Migration_2026_07_31_133028_AddParentidToTasks implements Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    final hasParentId = columns.any((col) => col['name'] == 'parentId');
    if (!hasParentId) {
      await db.execute('ALTER TABLE tasks ADD COLUMN parentId TEXT');
    }
  }
}
