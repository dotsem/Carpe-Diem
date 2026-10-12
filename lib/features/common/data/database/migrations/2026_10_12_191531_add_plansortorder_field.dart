// ignore_for_file: file_names, camel_case_types
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../migration.dart';

class Migration_2026_10_12_191531_AddPlansortorderField implements Migration {
  @override
  int get version => 7;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    final hasPlanSortOrder = columns.any(
      (col) => col['name'] == 'planSortOrder',
    );
    if (!hasPlanSortOrder) {
      await db.execute('ALTER TABLE tasks ADD COLUMN planSortOrder TEXT');
    }
  }
}
