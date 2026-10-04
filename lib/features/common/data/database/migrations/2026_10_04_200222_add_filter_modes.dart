// ignore_for_file: file_names, camel_case_types
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../migration.dart';

class Migration_2026_10_04_200222_AddFilterModes implements Migration {
  @override
  int get version => 6;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS filter_modes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon_code_point INTEGER,
        filter TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
