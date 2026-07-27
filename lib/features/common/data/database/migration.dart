import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class Migration {
  int get version;
  Future<void> up(DatabaseExecutor db);
}

class MigrationRunner {
  final List<Migration> _migrations;

  MigrationRunner([List<Migration>? migrations])
    : _migrations = List.unmodifiable(
        (migrations ?? [])..sort((a, b) => a.version.compareTo(b.version)),
      );

  Future<void> run(Database db, int oldVersion, int newVersion) async {
    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await db.transaction((txn) async {
          await migration.up(txn);
        });
      }
    }
  }
}
