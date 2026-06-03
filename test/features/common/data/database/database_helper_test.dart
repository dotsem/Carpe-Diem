import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;
    late Database db;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
    });

    tearDown(() async {
      await db.close();
    });

    test('should successfully open an in-memory database and create tables', () async {
      expect(db.isOpen, isTrue);

      final tables = [
        'projects',
        'labels',
        'project_labels',
        'tasks',
        'task_labels',
        'settings'
      ];

      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        expect(result, isNotEmpty, reason: 'Table $table should exist');
      }
    });

    test('should enforce foreign keys on the created database', () async {
      // Turn on foreign keys explicitly just in case FFI hasn't done it
      await db.execute('PRAGMA foreign_keys = ON');

      // Attempt to insert into tasks with a non-existent projectId
      // This should fail because tasks.projectId references projects.id
      expect(
        () => db.insert('tasks', {
          'id': 'test-task-1',
          'title': 'Orphan Task',
          'projectId': 'non-existent-project',
          'createdAt': DateTime.now().toIso8601String(),
          'isCompleted': 0,
          'status': 0,
          'priority': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
