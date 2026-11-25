import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('tasks', () {
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
      await db.insert('labels', {
        'id': 'label-1',
        'name': 'Work',
        'color': 0xFFFFFFFF,
      });

      final task = Task(
        id: 'task-1',
        title: 'Review PR',
        description: 'Read and verify',
        isUrgent: true,
        labelIds: const ['label-1'],
        createdAt: DateTime.now(),
      );

      await repository.insert(task);

      final fetched = await repository.getById('task-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Review PR'));
      expect(fetched.description, equals('Read and verify'));
      expect(fetched.isUrgent, isTrue);
      expect(fetched.labelIds, contains('label-1'));
    });

    test('should insert and fetch a task with tag mappings', () async {
      await db.insert('tags', {'id': 'tag-1', 'name': 'bug'});

      final task = Task(
        id: 'task-2',
        title: 'Fix issue',
        description: 'Read and fix',
        isUrgent: true,
        tagIds: const ['tag-1'],
        createdAt: DateTime.now(),
      );

      await repository.insert(task);

      final fetched = await repository.getById('task-2');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Fix issue'));
      expect(fetched.tagIds, contains('tag-1'));
    });

    test('should update a task and synchronize its tag mappings', () async {
      await db.insert('tags', {'id': 'tag-1', 'name': 'bug'});
      await db.insert('tags', {'id': 'tag-2', 'name': 'feature'});

      final task = Task(
        id: 'task-3',
        title: 'Initial task',
        tagIds: const ['tag-1'],
        createdAt: DateTime.now(),
      );

      await repository.insert(task);

      final updatedTask = task.copyWith(
        title: 'Updated task',
        tagIds: const ['tag-2'],
      );

      await repository.update(updatedTask);

      final fetched = await repository.getById('task-3');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Updated task'));
      expect(fetched.tagIds, isNot(contains('tag-1')));
      expect(fetched.tagIds, contains('tag-2'));
    });

    test('updateAll rolls back all updates when one fails', () async {
      final first = Task(
        id: 'batch-1',
        title: 'First',
        createdAt: DateTime.now(),
      );
      final second = Task(
        id: 'batch-2',
        title: 'Second',
        createdAt: DateTime.now(),
      );
      await repository.insert(first);
      await repository.insert(second);
      await db.execute('''
        CREATE TRIGGER fail_second_update
        BEFORE UPDATE ON tasks
        WHEN NEW.id = 'batch-2'
        BEGIN
          SELECT RAISE(ABORT, 'second update failed');
        END
      ''');

      await expectLater(
        repository.updateAll([
          first.copyWith(title: 'Updated first'),
          second.copyWith(title: 'Updated second'),
        ]),
        throwsA(isA<DatabaseException>()),
      );

      expect((await repository.getById(first.id))?.title, 'First');
      expect((await repository.getById(second.id))?.title, 'Second');
    });

    test(
      'should retrieve tasks by scheduled date or completion date range',
      () async {
        final date = DateTime(2026, 6);
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
          completedAt: DateTime(2026, 6, 1, 10),
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
      },
    );

    test('should query overdue tasks excluding completed ones', () async {
      final today = DateTime(2026, 6, 15);

      final task1 = Task(
        id: 't1',
        title: 'Overdue Todo',
        scheduledDate: DateTime(2026, 6, 10),
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
      final task1 = Task(
        id: 't1',
        title: 'Unscheduled',
        createdAt: DateTime.now(),
      );
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

    test(
      'should resolve hierarchical dependencies and query blockedBy',
      () async {
        final parent = Task(
          id: 't-parent',
          title: 'Parent PR',
          createdAt: DateTime.now(),
        );
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
      },
    );

    test(
      'should cleanup task history completed past threshold retention limit',
      () async {
        final oldCompletedDate = DateTime.now().subtract(
          const Duration(days: 10),
        );
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
      },
    );

    test('should query subtasks by parent id', () async {
      final parent = createTestTask(id: 'p1', title: 'Parent Task');
      final sub1 = createTestTask(id: 's1', title: 'Subtask 1', parentId: 'p1');
      final sub2 = createTestTask(id: 's2', title: 'Subtask 2', parentId: 'p1');

      await repository.insert(parent);
      await repository.insert(sub1);
      await repository.insert(sub2);

      final subtasks = await repository.getByParent('p1');
      expect(subtasks.length, equals(2));
      expect(subtasks.map((t) => t.id), containsAll(['s1', 's2']));

      final emptySubtasks = await repository.getByParent('non-existent');
      expect(emptySubtasks, isEmpty);
    });

    test('nulls invalid foreign references on insert and update', () async {
      await repository.insert(
        Task(
          id: 'invalid',
          title: 'Invalid references',
          projectId: 'missing-project',
          blockedById: 'missing-blocker',
          parentId: 'missing-parent',
          createdAt: DateTime(2026),
        ),
      );

      var fetched = await repository.getById('invalid');
      expect(fetched!.projectId, isNull);
      expect(fetched.blockedById, isNull);
      expect(fetched.parentId, isNull);

      await repository.update(
        fetched.copyWith(
          projectId: 'still-missing',
          blockedById: 'still-missing',
          parentId: 'invalid',
        ),
      );
      fetched = await repository.getById('invalid');
      expect(fetched!.projectId, isNull);
      expect(fetched.blockedById, isNull);
      expect(fetched.parentId, isNull);
    });

    test('nulls a parent reference that points at the task itself', () async {
      await repository.insert(createTestTask(id: 'self', title: 'Self'));
      await repository.update(
        (await repository.getById('self'))!.copyWith(parentId: 'self'),
      );
      expect((await repository.getById('self'))!.parentId, isNull);
    });

    test('queries by project, project backlog, and inherited label', () async {
      await db.insert('projects', {
        'id': 'project',
        'name': 'Project',
        'color': 0,
        'createdAt': DateTime(2026).toIso8601String(),
      });
      await db.insert('labels', {'id': 'label', 'name': 'Label', 'color': 0});
      await db.insert('tags', {'id': 'tag', 'name': 'Tag'});
      await db.insert('project_labels', {
        'projectId': 'project',
        'labelId': 'label',
      });

      await repository.insert(
        Task(
          id: 'backlog',
          title: 'Backlog',
          projectId: 'project',
          labelIds: const ['label', 'missing-label'],
          tagIds: const ['tag', 'missing-tag'],
          createdAt: DateTime(2026),
        ),
      );
      await repository.insert(
        Task(
          id: 'scheduled',
          title: 'Scheduled',
          projectId: 'project',
          scheduledDate: DateTime(2026, 2),
          createdAt: DateTime(2026),
        ),
      );
      await repository.insert(
        Task(id: 'other', title: 'Other', createdAt: DateTime(2026)),
      );

      expect(
        (await repository.getByProject('project')).map((task) => task.id),
        containsAll(['backlog', 'scheduled']),
      );
      expect(
        (await repository.getByProjectUnscheduled('project')).single.id,
        'backlog',
      );
      expect(
        (await repository.getByLabel('label')).map((task) => task.id),
        containsAll(['backlog', 'scheduled']),
      );
      final all = await repository.getAll(prioritizeDeadlines: false);
      final backlog = all.singleWhere((task) => task.id == 'backlog');
      expect(backlog.labelIds, ['label']);
      expect(backlog.tagIds, ['tag']);
    });

    test('updates valid labels and handles a missing update target', () async {
      await db.insert('labels', {'id': 'label', 'name': 'Label', 'color': 0});
      final task = Task(id: 'task', title: 'Task', createdAt: DateTime(2026));
      await repository.insert(task);
      await repository.update(task.copyWith(labelIds: const ['label']));

      expect((await repository.getById('task'))!.labelIds, ['label']);
      await repository.update(
        Task(
          id: 'missing',
          title: 'Missing',
          labelIds: const ['label'],
          createdAt: DateTime(2026),
        ),
      );
      expect(await repository.getById('missing'), isNull);
    });

    test('can prioritize overdue tasks', () async {
      await repository.insert(
        Task(
          id: 'overdue',
          title: 'Overdue',
          scheduledDate: DateTime(2020),
          createdAt: DateTime(2026),
        ),
      );
      await repository.insert(
        Task(id: 'current', title: 'Current', createdAt: DateTime(2026)),
      );

      final result = await repository.getAll(prioritizeOverdue: true);

      expect(result.first.id, 'overdue');
    });

    test('deletes a task', () async {
      await repository.insert(
        Task(id: 'delete-me', title: 'Delete me', createdAt: DateTime(2026)),
      );

      await repository.delete('delete-me');

      expect(await repository.getById('delete-me'), isNull);
    });
  });
}
