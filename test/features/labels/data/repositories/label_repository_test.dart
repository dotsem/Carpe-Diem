import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/data/repositories/label_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LabelRepository', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late LabelRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repository = LabelRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('should insert and retrieve a label', () async {
      const label = Label(id: 'label-1', name: 'Work', color: Colors.blue);
      await repository.insert(label);

      final fetched = await repository.getById('label-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Work'));
      expect(fetched.color.toARGB32(), equals(Colors.blue.toARGB32()));
    });

    test('should retrieve all labels sorted by name', () async {
      const labelB = Label(id: 'label-2', name: 'Personal', color: Colors.green);
      const labelA = Label(id: 'label-1', name: 'Family', color: Colors.red);
      
      await repository.insert(labelB);
      await repository.insert(labelA);

      final list = await repository.getAll();
      expect(list.length, equals(2));
      expect(list[0].name, equals('Family')); // 'Family' before 'Personal'
      expect(list[1].name, equals('Personal'));
    });

    test('should update label details correctly', () async {
      const label = Label(id: 'label-1', name: 'Urgent', color: Colors.red);
      await repository.insert(label);

      final updated = label.copyWith(name: 'Critical', color: Colors.orange);
      await repository.update(updated);

      final fetched = await repository.getById('label-1');
      expect(fetched!.name, equals('Critical'));
      expect(fetched.color.toARGB32(), equals(Colors.orange.toARGB32()));
    });

    test('should delete labels successfully', () async {
      const label = Label(id: 'label-1', name: 'Temporary', color: Colors.grey);
      await repository.insert(label);

      await repository.delete('label-1');
      final fetched = await repository.getById('label-1');
      expect(fetched, isNull);
    });
  });
}
