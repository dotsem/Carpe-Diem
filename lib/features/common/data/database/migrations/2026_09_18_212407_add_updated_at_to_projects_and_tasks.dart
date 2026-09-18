// ignore_for_file: file_names, camel_case_types
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../migration.dart';

class Migration_2026_09_18_212407_AddUpdatedAtToProjectsAndTasks
    implements Migration {
  @override
  int get version => 5;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final projectColumns = await db.rawQuery('PRAGMA table_info(projects)');
    final hasProjectUpdatedAt = projectColumns.any(
      (col) => col['name'] == 'updatedAt',
    );
    if (!hasProjectUpdatedAt) {
      await db.execute('ALTER TABLE projects ADD COLUMN updatedAt TEXT');
    }

    final taskColumns = await db.rawQuery('PRAGMA table_info(tasks)');
    final hasTaskUpdatedAt = taskColumns.any(
      (col) => col['name'] == 'updatedAt',
    );
    if (!hasTaskUpdatedAt) {
      await db.execute('ALTER TABLE tasks ADD COLUMN updatedAt TEXT');
    }
  }
}
