import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tags/data/repositories/tag_icon_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagIconRepository', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late TagIconRepository repo;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repo = TagIconRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('should retrieve seeded icons', () async {
      final icons = await repo.getAllIconDatas();
      expect(icons, isNotEmpty);
      expect(icons['bug'], equals(Icons.bug_report));
      expect(icons['feat'], equals(Icons.add_circle));
    });

    test('should insert and retrieve a new icon', () async {
      await repo.setIconDataForTag('banana', Icons.face);
      final icons = await repo.getAllIconDatas();
      expect(icons['banana'], equals(Icons.face));
    });

    test('should delete an icon mapping', () async {
      await repo.setIconDataForTag('banana', Icons.face);
      var icons = await repo.getAllIconDatas();
      expect(icons['banana'], equals(Icons.face));

      await repo.deleteIconDataForTag('banana');
      icons = await repo.getAllIconDatas();
      expect(icons['banana'], isNull);
    });
  });
}
