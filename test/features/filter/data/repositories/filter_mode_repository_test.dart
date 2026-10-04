import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/data/repositories/filter_mode_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('FilterModeRepository', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late FilterModeRepository repo;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repo = FilterModeRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getAll returns empty list initially', () async {
      final modes = await repo.getAll();
      expect(modes, isEmpty);
    });

    test('insert and getById retrieves stored filter mode', () async {
      const mode = FilterMode(
        id: 'mode-1',
        name: 'Urgent Tasks',
        iconCodePoint: 0xe559,
        filter: TaskFilter(isUrgent: true, projectIdsIncluded: {'proj-1'}),
        isDefault: true,
      );

      await repo.insert(mode);

      final retrieved = await repo.getById('mode-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'mode-1');
      expect(retrieved.name, 'Urgent Tasks');
      expect(retrieved.iconCodePoint, 0xe559);
      expect(retrieved.filter.isUrgent, isTrue);
      expect(retrieved.filter.projectIdsIncluded, {'proj-1'});
      expect(retrieved.isDefault, isTrue);
    });

    test('update modifies existing filter mode', () async {
      const mode = FilterMode(
        id: 'mode-2',
        name: 'Initial Name',
        filter: TaskFilter(),
      );
      await repo.insert(mode);

      final updated = mode.copyWith(
        name: 'Updated Name',
        filter: const TaskFilter(tagIdsIncluded: {'tag-1'}),
      );
      await repo.update(updated);

      final retrieved = await repo.getById('mode-2');
      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.filter.tagIdsIncluded, {'tag-1'});
    });

    test('delete removes filter mode by id', () async {
      const mode = FilterMode(
        id: 'mode-3',
        name: 'To Delete',
        filter: TaskFilter(),
      );
      await repo.insert(mode);
      expect(await repo.getById('mode-3'), isNotNull);

      await repo.delete('mode-3');
      expect(await repo.getById('mode-3'), isNull);
    });
  });
}
