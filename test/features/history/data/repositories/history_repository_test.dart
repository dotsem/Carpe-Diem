import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/history/data/repositories/history_repository.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';

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

    test('should query completed tasks within date range and get first completed date', () async {
      final task1 = Task(
        id: 't1',
        title: 'Completed Task A',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 6, 1, 10, 0),
        createdAt: DateTime(2026, 5, 20),
      );
      final task2 = Task(
        id: 't2',
        title: 'Completed Task B',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 6, 10, 15, 0),
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

      final list = await historyRepo.getCompletedInRange(DateTime(2026, 6, 1), DateTime(2026, 6, 5));

      expect(list.length, equals(1));
      expect(list.first.id, equals('t1'));

      final firstDate = await historyRepo.getFirstCompletedDate();
      expect(firstDate, isNotNull);
      expect(firstDate!.year, equals(2026));
      expect(firstDate.month, equals(6));
      expect(firstDate.day, equals(1));
    });

    test('should compute a comprehensive HistoryOverview statistic mapping', () async {
      // Deadlines missed task
      final task1 = Task(
        id: 't1',
        title: 'Late Task',
        status: TaskStatus.done,
        deadline: DateTime(2026, 6, 5),
        completedAt: DateTime(2026, 6, 8),
        createdAt: DateTime(2026, 6, 1),
      );

      // On-time task
      final task2 = Task(
        id: 't2',
        title: 'On-time Task',
        status: TaskStatus.done,
        deadline: DateTime(2026, 6, 10),
        completedAt: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 1),
      );

      await taskRepo.insert(task1);
      await taskRepo.insert(task2);

      final overview = await historyRepo.getHistoryOverview(DateTime(2026, 6, 1), DateTime(2026, 6, 15));

      expect(overview.totalCompleted, equals(2));
      expect(overview.totalCreated, equals(2));
      expect(overview.missedDeadlines, equals(1));
    });
  });
}
