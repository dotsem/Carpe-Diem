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

  late Database db;
  late TaskRepository repo;
  final day1 = DateTime(2026, 11, 10);
  final day2 = DateTime(2026, 11, 11);

  Task task({DateTime? scheduled, TaskStatus status = TaskStatus.todo}) => Task(
    id: 't1',
    title: 'x',
    createdAt: DateTime(2026, 11),
    scheduledDate: scheduled,
    status: status,
  );

  Future<List<Map<String, Object?>>> events() =>
      db.query('task_events', orderBy: 'at, rowid');

  setUp(() async {
    db = await DatabaseHelper(dbPath: inMemoryDatabasePath).database;
    repo = TaskRepository(db);
  });

  tearDown(() => db.close());

  test('migration creates the task_events table', () async {
    expect(await events(), isEmpty);
  });

  test(
    'insert with a date logs a schedule event, without one logs nothing',
    () async {
      await repo.insert(task(scheduled: day1));
      final rows = await events();
      expect(rows, hasLength(1));
      expect(rows.single['type'], 'schedule');
      expect(rows.single['fromValue'], isNull);
      expect(rows.single['toValue'], isNotNull);

      await db.delete('tasks');
      await repo.insert(task());
      expect(await events(), isEmpty);
    },
  );

  test('reschedule logs, undo cancels, redo logs again', () async {
    await repo.insert(task(scheduled: day1));
    await repo.update(task(scheduled: day2));
    expect(await events(), hasLength(2));

    await repo.update(task(scheduled: day1));
    expect(await events(), hasLength(1));

    await repo.update(task(scheduled: day2));
    expect(await events(), hasLength(2));
  });

  test('completing then reopening cancels out', () async {
    await repo.insert(task());
    await repo.update(task(status: TaskStatus.done));
    expect(await events(), hasLength(1));
    await repo.update(task());
    expect(await events(), isEmpty);
  });

  test('unchanged update logs nothing', () async {
    await repo.insert(task(scheduled: day1));
    await repo.update(task(scheduled: day1));
    expect(await events(), hasLength(1));
  });

  test('deleting a task removes its events', () async {
    await repo.insert(task(scheduled: day1));
    await repo.delete('t1');
    expect(await events(), isEmpty);
  });
}
