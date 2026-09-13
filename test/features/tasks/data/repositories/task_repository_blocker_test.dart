import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskRepository - Blocker LEFT JOIN', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late TaskRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repository = TaskRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'joins incomplete blocker title and status onto dependent task',
      () async {
        final blocker = Task(
          id: 'blocker-1',
          title: 'API Schema Design',
          status: TaskStatus.todo,
          createdAt: DateTime.now(),
        );
        final dependent = Task(
          id: 'task-1',
          title: 'Implement Endpoints',
          blockedById: 'blocker-1',
          createdAt: DateTime.now(),
        );

        await repository.insert(blocker);
        await repository.insert(dependent);

        final fetched = await repository.getById('task-1');
        expect(fetched, isNotNull);
        expect(fetched!.blockerTitle, equals('API Schema Design'));
        expect(fetched.blockerStatus, equals(TaskStatus.todo));
        expect(fetched.isBlocked, isTrue);
      },
    );

    test('sets isBlocked to false when blocker is completed', () async {
      final blocker = Task(
        id: 'blocker-1',
        title: 'API Schema Design',
        status: TaskStatus.done,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      final dependent = Task(
        id: 'task-1',
        title: 'Implement Endpoints',
        blockedById: 'blocker-1',
        createdAt: DateTime.now(),
      );

      await repository.insert(blocker);
      await repository.insert(dependent);

      final fetched = await repository.getById('task-1');
      expect(fetched, isNotNull);
      expect(fetched!.blockerTitle, equals('API Schema Design'));
      expect(fetched.blockerStatus, equals(TaskStatus.done));
      expect(fetched.isBlocked, isFalse);
    });

    test('leaves blocker fields null when task has no blocker', () async {
      final task = Task(
        id: 'task-1',
        title: 'Independent Task',
        createdAt: DateTime.now(),
      );

      await repository.insert(task);

      final fetched = await repository.getById('task-1');
      expect(fetched, isNotNull);
      expect(fetched!.blockerTitle, isNull);
      expect(fetched.blockerStatus, isNull);
      expect(fetched.isBlocked, isFalse);
    });

    test('populates blocker fields in getByDate list query', () async {
      final today = DateTime.now();
      final blocker = Task(
        id: 'blocker-1',
        title: 'Setup Database',
        status: TaskStatus.inProgress,
        createdAt: today,
        scheduledDate: today,
      );
      final dependent = Task(
        id: 'task-1',
        title: 'Run Migrations',
        blockedById: 'blocker-1',
        createdAt: today,
        scheduledDate: today,
      );

      await repository.insert(blocker);
      await repository.insert(dependent);

      final tasks = await repository.getByDate(today);
      final fetchedDependent = tasks.firstWhere((t) => t.id == 'task-1');
      expect(fetchedDependent.blockerTitle, equals('Setup Database'));
      expect(fetchedDependent.blockerStatus, equals(TaskStatus.inProgress));
      expect(fetchedDependent.isBlocked, isTrue);
    });
  });
}
