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
      // First populate the labels table due to FOREIGN KEY constraints on project_labels
      await db.insert('labels', {'id': 'label-1', 'name': 'Work', 'color': 0xFFFFFFFF});

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
      await db.insert('labels', {'id': 'label-1', 'name': 'Work', 'color': 0xFFFFFFFF});
      await db.insert('labels', {'id': 'label-2', 'name': 'Personal', 'color': 0xFF000000});

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
      await db.insert('labels', {'id': 'label-1', 'name': 'Work', 'color': 0xFFFFFFFF});
      
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

      final mappings = await db.query('project_labels', where: 'projectId = ?', whereArgs: ['project-1']);
      expect(mappings, isEmpty);
    });

    test('should sort projects logically: deadlines, priority, and then name', () async {
      final pA = Project(
        id: 'pA',
        name: 'A_Project',
        color: Colors.blue,
        isUrgent: false,
        createdAt: DateTime.now(),
      );
      final pB = Project(
        id: 'pB',
        name: 'B_Project',
        color: Colors.blue,
        isUrgent: true, // Higher priority than A
        createdAt: DateTime.now(),
      );
      final pC = Project(
        id: 'pC',
        name: 'C_Project',
        color: Colors.blue,
        deadline: DateTime(2026, 6, 1), // Has a deadline (should come first)
        createdAt: DateTime.now(),
      );

      await repository.insert(pA);
      await repository.insert(pB);
      await repository.insert(pC);

      final sorted = await repository.getAll();
      expect(sorted[0].id, equals('pC')); // Has deadline
      expect(sorted[1].id, equals('pB')); // Higher priority
      expect(sorted[2].id, equals('pA')); // Lower priority
    });
  });
}
