import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/history/data/repositories/history_insights_repository.dart';
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
  late HistoryInsightsRepository repository;
  late TaskRepository tasks;

  setUp(() async {
    db = await DatabaseHelper(dbPath: inMemoryDatabasePath).database;
    repository = HistoryInsightsRepository(db);
    tasks = TaskRepository(db);
  });

  tearDown(() => db.close());

  Future<void> addProject(String id) => db.insert('projects', {
    'id': id,
    'name': id,
    'color': 0,
    'createdAt': DateTime(2026).toIso8601String(),
  });

  test('returns completions and open counts grouped by project', () async {
    await addProject('p1');
    await addProject('p2');
    await tasks.insert(
      Task(
        id: 'done',
        title: 'Done',
        projectId: 'p1',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 2, 3),
        createdAt: DateTime(2026),
      ),
    );
    await tasks.insert(
      Task(
        id: 'open-1',
        title: 'Open one',
        projectId: 'p1',
        createdAt: DateTime(2026),
      ),
    );
    await tasks.insert(
      Task(
        id: 'open-2',
        title: 'Open two',
        projectId: 'p2',
        status: TaskStatus.inProgress,
        createdAt: DateTime(2026),
      ),
    );
    await tasks.insert(
      Task(id: 'none', title: 'No project', createdAt: DateTime(2026)),
    );

    final completions = await repository.getCompletionsSince(DateTime(2026));
    final counts = await repository.getOpenCountsByProject();

    expect(completions, [(projectId: 'p1', completedAt: DateTime(2026, 2, 3))]);
    expect(counts, {'p1': 1, 'p2': 1});
  });

  test(
    'tracking start is null without events and then returns earliest',
    () async {
      expect(await repository.getTrackingStart(), isNull);
      await tasks.insert(
        Task(
          id: 'scheduled',
          title: 'Scheduled',
          scheduledDate: DateTime(2026, 3, 4),
          createdAt: DateTime(2026),
        ),
      );
      await db.update('task_events', {
        'at': DateTime(2026, 1, 2).toIso8601String(),
      });

      expect(await repository.getTrackingStart(), DateTime(2026, 1, 2));
    },
  );

  test('returns lead times with and without a first schedule event', () async {
    await addProject('p1');
    await tasks.insert(
      Task(
        id: 'with-event',
        title: 'With event',
        projectId: 'p1',
        status: TaskStatus.done,
        scheduledDate: DateTime(2026, 1, 4),
        createdAt: DateTime(2026),
        completedAt: DateTime(2026, 1, 8),
      ),
    );
    await tasks.insert(
      Task(
        id: 'without-event',
        title: 'Without event',
        status: TaskStatus.done,
        createdAt: DateTime(2026, 1, 2),
        completedAt: DateTime(2026, 1, 9),
      ),
    );

    final rows = await repository.getLeadTimeRows(
      DateTime(2026),
      DateTime(2026, 2),
    );

    expect(rows, hasLength(2));
    expect(rows.first.projectId, 'p1');
    expect(rows.first.firstScheduledAt, isNotNull);
    expect(rows.last.firstScheduledAt, isNull);
  });

  test('counts schedule moves and constructs schedule timelines', () async {
    await tasks.insert(
      Task(
        id: 'moving',
        title: 'Moving',
        status: TaskStatus.done,
        scheduledDate: DateTime(2026, 1, 5),
        createdAt: DateTime(2026),
        completedAt: DateTime(2026, 1, 8),
      ),
    );
    final original = (await tasks.getById('moving'))!;
    await tasks.update(original.copyWith(scheduledDate: DateTime(2026, 1, 6)));

    final slips = await repository.getSlipRows(
      DateTime(2026),
      DateTime(2026, 2),
    );
    final timelines = await repository.getScheduleTimelines(
      DateTime(2026),
      DateTime(2026, 2),
    );

    expect(slips.single.id, 'moving');
    expect(slips.single.moves, 1);
    expect(timelines, hasLength(1));
    expect(timelines.single.current, DateTime(2026, 1, 6));
    expect(timelines.single.completedAt, DateTime(2026, 1, 8));
    expect(timelines.single.events, hasLength(2));
    expect(timelines.single.events.first.from, isNull);
    expect(timelines.single.events.first.to, DateTime(2026, 1, 5));
    expect(timelines.single.events.last.from, DateTime(2026, 1, 5));
    expect(timelines.single.events.last.to, DateTime(2026, 1, 6));
  });
}
