import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/settings/data/repositories/settings_repository.dart';
import 'package:carpe_diem/features/labels/data/repositories/label_repository.dart';
import 'package:carpe_diem/features/projects/data/repositories/project_repository.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';
import 'package:carpe_diem/features/history/data/repositories/history_repository.dart';

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in ProviderScope');
});

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
});

final labelRepositoryProvider = Provider<ILabelRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LabelRepository(db);
});

final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepository(db);
});

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db);
});

final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoryRepository(db);
});
