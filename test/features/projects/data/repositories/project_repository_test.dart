import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/data/repositories/project_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('projects', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late ProjectRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repository = ProjectRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('should insert and retrieve a project with label mappings', () async {
      await db.insert('labels', {
        'id': 'label-1',
        'name': 'Work',
        'color': 0xFFFFFFFF,
      });

      final project = Project(
        id: 'project-1',
        name: 'Launch App',
        description: 'Prepare and deploy',
        color: Colors.blue,
        isUrgent: true,
        labelIds: const ['label-1'],
        createdAt: DateTime(2026, 6, 1),
      );

      await repository.insert(project);

      final fetched = await repository.getById('project-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Launch App'));
      expect(fetched.description, equals('Prepare and deploy'));
      expect(fetched.isUrgent, isTrue);
      expect(fetched.labelIds, contains('label-1'));
      expect(fetched.isActive, isTrue);
    });

    test('should update a project and overwrite label mappings', () async {
      await db.insert('labels', {
        'id': 'label-1',
        'name': 'Work',
        'color': 0xFFFFFFFF,
      });
      await db.insert('labels', {
        'id': 'label-2',
        'name': 'Personal',
        'color': 0xFF000000,
      });

      final project = Project(
        id: 'project-1',
        name: 'Draft Version',
        color: Colors.grey,
        labelIds: const ['label-1'],
        createdAt: DateTime(2026, 6, 1),
      );
      await repository.insert(project);

      final updated = project.copyWith(
        name: 'V1.0 Launch',
        description: 'New Description',
        color: Colors.red,
        isUrgent: true,
        labelIds: const ['label-2'],
        isActive: false,
      );
      await repository.update(updated);

      final fetched = await repository.getById('project-1');
      expect(fetched!.name, equals('V1.0 Launch'));
      expect(fetched.description, equals('New Description'));
      expect(fetched.color.toARGB32(), equals(Colors.red.toARGB32()));
      expect(fetched.isUrgent, isTrue);
      expect(fetched.labelIds, contains('label-2'));
      expect(fetched.labelIds, isNot(contains('label-1')));
      expect(fetched.isActive, isFalse);
    });

    test('should delete a project and cascade delete project_labels', () async {
      await db.insert('labels', {
        'id': 'label-1',
        'name': 'Work',
        'color': 0xFFFFFFFF,
      });

      final project = Project(
        id: 'project-1',
        name: 'Temp Project',
        color: Colors.blue,
        labelIds: const ['label-1'],
        createdAt: DateTime.now(),
      );
      await repository.insert(project);

      await repository.delete('project-1');
      final fetched = await repository.getById('project-1');
      expect(fetched, isNull);

      final mappings = await db.query(
        'project_labels',
        where: 'projectId = ?',
        whereArgs: ['project-1'],
      );
      expect(mappings, isEmpty);
    });

    test(
      'should sort projects logically: urgent first, then sortOrder, then createdAt',
      () async {
        final pA = Project(
          id: 'pA',
          name: 'A_Project',
          color: Colors.blue,
          isUrgent: false,
          sortOrder: 'c',
          createdAt: DateTime(2026, 1, 1),
        );
        final pB = Project(
          id: 'pB',
          name: 'B_Project',
          color: Colors.blue,
          isUrgent: false,
          sortOrder: 'b',
          createdAt: DateTime(2026, 1, 2),
        );
        final pC = Project(
          id: 'pC',
          name: 'C_Project',
          color: Colors.blue,
          isUrgent: true,
          sortOrder: 'z',
          createdAt: DateTime(2026, 1, 3),
        );

        await repository.insert(pA);
        await repository.insert(pB);
        await repository.insert(pC);

        final sorted = await repository.getAll();
        expect(sorted[0].id, equals('pC'));
        expect(sorted[1].id, equals('pB'));
        expect(sorted[2].id, equals('pA'));
      },
    );
  });
}
