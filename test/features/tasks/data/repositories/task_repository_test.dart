import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskRepository', () {
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

    test('should insert and fetch a task with label mappings', () async {
      await db.insert('labels', {'id': 'label-1', 'name': 'Work', 'color': 0xFFFFFFFF});

      final task = Task(
        id: 'task-1',
        title: 'Review PR',
        description: 'Read and verify',
        priority: Priority.high,
        labelIds: const ['label-1'],
        createdAt: DateTime.now(),
      );

      await repository.insert(task);

      final fetched = await repository.getById('task-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Review PR'));
      expect(fetched.description, equals('Read and verify'));
      expect(fetched.priority, equals(Priority.high));
      expect(fetched.labelIds, contains('label-1'));
    });

    test('should retrieve tasks by scheduled date or completion date range', () async {
      final date = DateTime(2026, 6, 1);
      final task1 = Task(
        id: 't1',
        title: 'Scheduled Task',
        scheduledDate: date,
        createdAt: DateTime.now(),
      );
      final task2 = Task(
        id: 't2',
        title: 'Completed Today Task',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 6, 1, 10, 0),
        createdAt: DateTime.now(),
      );
      final task3 = Task(
        id: 't3',
        title: 'Other Task',
        scheduledDate: DateTime(2026, 6, 2),
        createdAt: DateTime.now(),
      );

      await repository.insert(task1);
      await repository.insert(task2);
      await repository.insert(task3);

      final tasks = await repository.getByDate(date);
      expect(tasks.length, equals(2));
      final ids = tasks.map((t) => t.id).toList();
      expect(ids, contains('t1'));
      expect(ids, contains('t2'));
      expect(ids, isNot(contains('t3')));
    });

    test('should query overdue tasks excluding completed ones', () async {
      final today = DateTime(2026, 6, 15);
      
      final task1 = Task(
        id: 't1',
        title: 'Overdue Todo',
        scheduledDate: DateTime(2026, 6, 10),
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      );
      final task2 = Task(
        id: 't2',
        title: 'Overdue Done',
        scheduledDate: DateTime(2026, 6, 10),
        status: TaskStatus.done,
        createdAt: DateTime.now(),
      );
      final task3 = Task(
        id: 't3',
        title: 'Future Task',
        scheduledDate: DateTime(2026, 6, 20),
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      );

      await repository.insert(task1);
      await repository.insert(task2);
      await repository.insert(task3);

      final overdue = await repository.getOverdue(today);
      expect(overdue.length, equals(1));
      expect(overdue.first.id, equals('t1'));
    });

    test('should query unscheduled backlog tasks', () async {
      final task1 = Task(id: 't1', title: 'Unscheduled', createdAt: DateTime.now());
      final task2 = Task(
        id: 't2',
        title: 'Scheduled',
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.insert(task1);
      await repository.insert(task2);

      final unscheduled = await repository.getUnscheduled();
      expect(unscheduled.length, equals(1));
      expect(unscheduled.first.id, equals('t1'));
    });

    test('should resolve hierarchical dependencies and query blockedBy', () async {
      final parent = Task(id: 't-parent', title: 'Parent PR', createdAt: DateTime.now());
      final blocker = Task(
        id: 't-blocker',
        title: 'Blocker Bug',
        blockedById: 't-parent',
        createdAt: DateTime.now(),
      );

      await repository.insert(parent);
      await repository.insert(blocker);

      final blockedTasks = await repository.getByBlockedBy('t-parent');
      expect(blockedTasks.length, equals(1));
      expect(blockedTasks.first.id, equals('t-blocker'));
    });

    test('should cleanup task history completed past threshold retention limit', () async {
      final oldCompletedDate = DateTime.now().subtract(const Duration(days: 10));
      final task = Task(
        id: 't-old',
        title: 'Old Task',
        status: TaskStatus.done,
        completedAt: oldCompletedDate,
        createdAt: DateTime.now(),
      );
      await repository.insert(task);

      final cleanedCount = await repository.cleanupHistory(5);
      expect(cleanedCount, equals(1));

      final fetched = await repository.getById('t-old');
      expect(fetched, isNull);
    });
  });
}
