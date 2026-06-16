import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';

abstract class ITaskRepository {
  Future<List<Task>> getAll({bool prioritizeDeadlines = true});
  Future<Task?> getById(String id);
  Future<List<Task>> getByBlockedBy(String taskId);
  Future<List<Task>> getByDate(DateTime date, {bool prioritizeDeadlines = true});
  Future<List<Task>> getOverdue(DateTime today);
  Future<List<Task>> getUnscheduled({bool prioritizeDeadlines = true});
  Future<List<Task>> getByProject(String projectId, {bool prioritizeDeadlines = true});
  Future<List<Task>> getByLabel(String labelId, {bool prioritizeDeadlines = true});
  Future<void> insert(Task task);
  Future<void> update(Task task);
  Future<void> delete(String id);
  Future<int> cleanupHistory(int days);
}

abstract class IHistoryRepository {
  Future<List<Task>> getCompletedInRange(DateTime start, DateTime end, {int? limit, int? offset, TaskFilter? filter});
  Future<DateTime?> getFirstCompletedDate();
  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter});
}

abstract class IProjectRepository {
  Future<List<Project>> getAll();
  Future<Project?> getById(String id);
  Future<void> insert(Project project);
  Future<void> update(Project project);
  Future<void> delete(String id);
}

abstract class ILabelRepository {
  Future<List<Label>> getAll();
  Future<Label?> getById(String id);
  Future<void> insert(Label label);
  Future<void> update(Label label);
  Future<void> delete(String id);
}

abstract class ISettingsRepository {
  Future<void> set(String key, String value);
  Future<String?> get(String key);
  Future<Map<String, String>> getAll();
}

abstract class IRepository {
  Future<void> clearHistory();
}
