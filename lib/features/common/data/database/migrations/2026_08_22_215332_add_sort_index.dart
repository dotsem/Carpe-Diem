// ignore_for_file: file_names, camel_case_types
import 'package:carpe_diem/features/common/data/database/migration.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Migration_2026_08_22_215332_AddSortIndex implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_sort ON tasks(isUrgent DESC, sortOrder ASC)',
    );
  }
}
