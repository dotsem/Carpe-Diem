import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/common/data/database/migration.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('common', () {
    late DatabaseHelper dbHelper;
    late Database db;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'should successfully open an in-memory database and create tables',
      () async {
        expect(db.isOpen, isTrue);

        final tables = [
          'projects',
          'labels',
          'project_labels',
          'tasks',
          'task_labels',
          'settings',
          'tags',
          'task_tags',
          'tag_icons',
        ];

        for (final table in tables) {
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [table],
          );
          expect(result, isNotEmpty, reason: 'Table $table should exist');
        }
      },
    );

    test('should seed initial tag icons in tag_icons table', () async {
      final results = await db.query('tag_icons');
      expect(results, isNotEmpty);

      final bugIcon = results.firstWhere((r) => r['tag_name'] == 'bug');
      expect(bugIcon['icon_code_point'], isNotNull);

      final featIcon = results.firstWhere((r) => r['tag_name'] == 'feat');
      expect(featIcon['icon_code_point'], isNotNull);
    });

    test('should enforce foreign keys on the created database', () async {
      await db.execute('PRAGMA foreign_keys = ON');

      expect(
        () => db.insert('tasks', {
          'id': 'test-task-1',
          'title': 'Orphan Task',
          'projectId': 'non-existent-project',
          'createdAt': DateTime.now().toIso8601String(),
          'isCompleted': 0,
          'status': 0,
          'isUrgent': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('MigrationRunner', () {
    test('executes applicable migrations in sequential order', () async {
      final db = await openDatabase(inMemoryDatabasePath, version: 1);
      final executed = <int>[];

      final runner = MigrationRunner([
        _TestMigration(2, () => executed.add(2)),
        _TestMigration(1, () => executed.add(1)),
        _TestMigration(3, () => executed.add(3)),
      ]);

      await runner.run(db, 1, 3);
      expect(executed, equals([2, 3]));
      await db.close();
    });
  });
}

class _TestMigration implements Migration {
  @override
  final int version;
  final Function() onUp;

  _TestMigration(this.version, this.onUp);

  @override
  Future<void> up(DatabaseExecutor db) async => onUp();
}
