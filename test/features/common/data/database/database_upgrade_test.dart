import 'dart:io';

import 'package:carpe_diem/features/common/data/database/constants/db_constants.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory dir;
  late String path;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('carpe_upgrade_test');
    path = p.join(dir.path, 'old.db');
    final old = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE projects (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
        );
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            isUrgent INTEGER NOT NULL DEFAULT 0,
            sortOrder TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');
        for (final (id, order, day) in [
          ('c', '', '2026-01-03'),
          ('a', '', '2026-01-01'),
          ('kept', 'zz', '2026-01-02'),
          ('b', '', '2026-01-02'),
        ]) {
          await db.insert('tasks', {
            'id': id,
            'title': id,
            'sortOrder': order,
            'createdAt': day,
          });
        }
      },
    );
    await old.close();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('upgrading an old database applies every migration in order', () async {
    final db = await DatabaseHelper(dbPath: path).database;
    addTearDown(db.close);

    expect(await db.getVersion(), DbConstants.dbVersion);

    final taskColumns = (await db.rawQuery(
      'PRAGMA table_info(tasks)',
    )).map((c) => c['name']).toSet();
    expect(
      taskColumns,
      containsAll(['parentId', 'updatedAt', 'planSortOrder']),
    );

    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((t) => t['name']).toSet();
    expect(tables, containsAll(['filter_modes', 'task_events']));
  });

  test('upgrade backfills empty sort orders by creation date', () async {
    final db = await DatabaseHelper(dbPath: path).database;
    addTearDown(db.close);

    final rows = await db.query('tasks', orderBy: 'sortOrder ASC');
    final rank = {
      for (final r in rows) r['id']! as String: r['sortOrder']! as String,
    };

    expect(rank['kept'], 'zz');
    expect(rank['a'], isNotEmpty);
    expect(rank['a']!.compareTo(rank['b']!), isNegative);
    expect(rank['b']!.compareTo(rank['c']!), isNegative);
  });
}
