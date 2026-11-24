import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/common/data/database/migration.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/repositories/filter_mode_repository.dart';
import 'package:carpe_diem/features/history/data/repositories/history_insights_repository.dart';
import 'package:carpe_diem/features/history/data/repositories/history_repository.dart';
import 'package:carpe_diem/features/labels/data/repositories/label_repository.dart';
import 'package:carpe_diem/features/projects/data/repositories/project_repository.dart';
import 'package:carpe_diem/features/settings/data/repositories/settings_repository.dart';
import 'package:carpe_diem/features/tags/data/repositories/tag_icon_repository.dart';
import 'package:carpe_diem/features/tags/data/repositories/tag_repository.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('constructs every repository from the shared database', () async {
    await DatabaseHelper.initialize();
    final db = await DatabaseHelper(dbPath: inMemoryDatabasePath).database;
    addTearDown(db.close);
    await MigrationRunner().run(db, 0, 0);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(keyValueRepositoryProvider),
      isA<SettingsRepository>(),
    );
    expect(container.read(labelRepositoryProvider), isA<LabelRepository>());
    expect(container.read(projectRepositoryProvider), isA<ProjectRepository>());
    expect(container.read(taskRepositoryProvider), isA<TaskRepository>());
    expect(container.read(historyRepositoryProvider), isA<HistoryRepository>());
    expect(
      container.read(historyInsightsRepositoryProvider),
      isA<HistoryInsightsRepository>(),
    );
    expect(container.read(tagRepositoryProvider), isA<TagRepository>());
    expect(container.read(tagIconRepositoryProvider), isA<TagIconRepository>());
    expect(
      container.read(filterModeRepositoryProvider),
      isA<FilterModeRepository>(),
    );
  });

  test('database provider requires an override', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(databaseProvider), throwsA(anything));
  });
}
