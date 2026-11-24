import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/repositories/history_repository.dart';
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

  group('history', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late HistoryRepository historyRepo;
    late TaskRepository taskRepo;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      historyRepo = HistoryRepository(db);
      taskRepo = TaskRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'should query completed tasks within date range and get first completed date',
      () async {
        final task1 = Task(
          id: 't1',
          title: 'Completed Task A',
          status: TaskStatus.done,
          completedAt: DateTime(2026, 6, 1, 10),
          createdAt: DateTime(2026, 5, 20),
        );
        final task2 = Task(
          id: 't2',
          title: 'Completed Task B',
          status: TaskStatus.done,
          completedAt: DateTime(2026, 6, 10, 15),
          createdAt: DateTime(2026, 5, 20),
        );
        final task3 = Task(
          id: 't3',
          title: 'In Progress Task',
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 5, 20),
        );

        await taskRepo.insert(task1);
        await taskRepo.insert(task2);
        await taskRepo.insert(task3);

        final list = await historyRepo.getCompletedInRange(
          DateTime(2026, 6),
          DateTime(2026, 6, 5),
        );

        expect(list.length, equals(1));
        expect(list.first.id, equals('t1'));

        final firstDate = await historyRepo.getFirstCompletedDate();
        expect(firstDate, isNotNull);
        expect(firstDate!.year, equals(2026));
        expect(firstDate.month, equals(6));
        expect(firstDate.day, equals(1));
      },
    );

    test('returns null when no task has been completed', () async {
      expect(await historyRepo.getFirstCompletedDate(), isNull);
    });

    test('filters completed tasks by every supported filter field', () async {
      final completedAt = DateTime(2026, 6, 5);
      await db.insert('projects', {
        'id': 'p1',
        'name': 'One',
        'color': 0,
        'createdAt': DateTime(2026).toIso8601String(),
      });
      await db.insert('projects', {
        'id': 'p2',
        'name': 'Two',
        'color': 0,
        'createdAt': DateTime(2026).toIso8601String(),
      });
      for (final id in ['l1', 'l2']) {
        await db.insert('labels', {'id': id, 'name': id, 'color': 0});
      }
      for (final id in ['tag1', 'tag2']) {
        await db.insert('tags', {'id': id, 'name': id});
      }
      await db.insert('project_labels', {'projectId': 'p2', 'labelId': 'l2'});

      await taskRepo.insert(
        Task(
          id: 'urgent',
          title: 'Urgent',
          projectId: 'p1',
          isUrgent: true,
          status: TaskStatus.done,
          completedAt: completedAt,
          createdAt: completedAt,
          labelIds: const ['l1'],
          tagIds: const ['tag1'],
        ),
      );
      await taskRepo.insert(
        Task(
          id: 'inherited',
          title: 'Inherited label',
          projectId: 'p2',
          status: TaskStatus.done,
          completedAt: completedAt.add(const Duration(hours: 1)),
          createdAt: DateTime(2026),
          tagIds: const ['tag2'],
        ),
      );
      await taskRepo.insert(
        Task(
          id: 'unassigned',
          title: 'Unassigned',
          status: TaskStatus.done,
          completedAt: completedAt.add(const Duration(hours: 2)),
          createdAt: DateTime(2026),
        ),
      );

      Future<List<String>> ids(TaskFilter filter) async =>
          (await historyRepo.getCompletedInRange(
            DateTime(2026, 6),
            DateTime(2026, 7),
            filter: filter,
          )).map((task) => task.id).toList();

      expect(await ids(const TaskFilter(isUrgent: true)), ['urgent']);
      expect(await ids(const TaskFilter(isUrgent: false)), [
        'unassigned',
        'inherited',
      ]);
      expect(await ids(const TaskFilter(projectIdsIncluded: {'p1'})), [
        'urgent',
      ]);
      expect(await ids(const TaskFilter(projectIdsExcluded: {'p1'})), [
        'unassigned',
        'inherited',
      ]);
      expect(await ids(const TaskFilter(labelIdsIncluded: {'l1'})), ['urgent']);
      expect(await ids(const TaskFilter(labelIdsIncluded: {'l2'})), [
        'inherited',
      ]);
      expect(await ids(const TaskFilter(labelIdsExcluded: {'l1'})), [
        'unassigned',
        'inherited',
      ]);
      expect(await ids(const TaskFilter(labelIdsExcluded: {'l2'})), [
        'unassigned',
        'urgent',
      ]);
      expect(await ids(const TaskFilter(tagIdsIncluded: {'tag1'})), ['urgent']);
      expect(await ids(const TaskFilter(tagIdsExcluded: {'tag1'})), [
        'unassigned',
        'inherited',
      ]);

      final filteredOverview = await historyRepo.getHistoryOverview(
        DateTime(2026, 6),
        DateTime(2026, 7),
        filter: const TaskFilter(projectIdsIncluded: {'p1'}),
      );
      expect(filteredOverview.totalCompleted, 1);
      expect(filteredOverview.totalCreated, 1);
    });

    test('applies pagination and loads labels and tags', () async {
      await db.insert('labels', {'id': 'label', 'name': 'Label', 'color': 0});
      await db.insert('tags', {'id': 'tag', 'name': 'Tag'});
      for (var i = 0; i < 3; i++) {
        await taskRepo.insert(
          Task(
            id: 'task-$i',
            title: 'Task $i',
            status: TaskStatus.done,
            completedAt: DateTime(2026, 6, i + 1),
            createdAt: DateTime(2026),
            labelIds: i == 1 ? const ['label'] : const [],
            tagIds: i == 1 ? const ['tag'] : const [],
          ),
        );
      }

      final result = await historyRepo.getCompletedInRange(
        DateTime(2026, 6),
        DateTime(2026, 7),
        limit: 1,
        offset: 1,
      );

      expect(result.single.id, 'task-1');
      expect(result.single.labelIds, ['label']);
      expect(result.single.tagIds, ['tag']);
    });

    test(
      'should compute a comprehensive HistoryOverview statistic mapping',
      () async {
        // Deadlines missed task
        final task1 = Task(
          id: 't1',
          title: 'Late Task',
          status: TaskStatus.done,
          deadline: DateTime(2026, 6, 5),
          completedAt: DateTime(2026, 6, 8),
          createdAt: DateTime(2026, 6),
        );

        // On-time task
        final task2 = Task(
          id: 't2',
          title: 'On-time Task',
          status: TaskStatus.done,
          deadline: DateTime(2026, 6, 10),
          completedAt: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6),
        );

        await taskRepo.insert(task1);
        await taskRepo.insert(task2);

        final overview = await historyRepo.getHistoryOverview(
          DateTime(2026, 6),
          DateTime(2026, 6, 15),
        );

        expect(overview.totalCompleted, equals(2));
        expect(overview.totalCreated, equals(2));
        expect(overview.missedDeadlines, equals(1));
      },
    );
  });
}
