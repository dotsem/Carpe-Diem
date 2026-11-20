// ignore_for_file: file_names, camel_case_types
import 'package:carpe_diem/features/common/data/database/migration.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Migration_2026_11_17_124523_AddTaskEvents implements Migration {
  @override
  int get version => 8;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_events (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        at TEXT NOT NULL,
        fromValue TEXT,
        toValue TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_events_task ON task_events(taskId, at)',
    );
  }
}
