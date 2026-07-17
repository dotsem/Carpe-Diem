import 'package:flutter/widgets.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';

abstract class ICrudRepository<T> {
  String get repositoryName;
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> insert(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}

abstract class ITaskRepository implements ICrudRepository<Task> {
  @override
  String get repositoryName => 'task';
  @override
  Future<List<Task>> getAll({bool prioritizeDeadlines = true});
  @override
  Future<Task?> getById(String id);
  Future<List<Task>> getByBlockedBy(String taskId);
  Future<List<Task>> getByDate(DateTime date, {bool prioritizeDeadlines = true});
  Future<List<Task>> getOverdue(DateTime today);
  Future<List<Task>> getUnscheduled({bool prioritizeDeadlines = true});
  Future<List<Task>> getByProject(String projectId, {bool prioritizeDeadlines = true});
  Future<List<Task>> getByLabel(String labelId, {bool prioritizeDeadlines = true});

  @override
  Future<void> insert(Task task);
  @override
  Future<void> update(Task task);
  @override
  Future<void> delete(String id);
  Future<int> cleanupHistory(int days);
}

abstract class IHistoryRepository {
  Future<List<Task>> getCompletedInRange(DateTime start, DateTime end, {int? limit, int? offset, TaskFilter? filter});
  Future<DateTime?> getFirstCompletedDate();
  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter});
}

abstract class IProjectRepository implements ICrudRepository<Project> {
  @override
  String get repositoryName => 'project';
  @override
  Future<List<Project>> getAll();
  @override
  Future<Project?> getById(String id);
  @override
  Future<void> insert(Project project);
  @override
  Future<void> update(Project project);
  @override
  Future<void> delete(String id);
}

abstract class ILabelRepository implements ICrudRepository<Label> {
  @override
  String get repositoryName => 'label';
  @override
  Future<List<Label>> getAll();
  @override
  Future<Label?> getById(String id);
  @override
  Future<void> insert(Label label);
  @override
  Future<void> update(Label label);
  @override
  Future<void> delete(String id);
}

abstract class ITagRepository implements ICrudRepository<Tag> {
  @override
  String get repositoryName => 'tag';
  @override
  Future<List<Tag>> getAll();
  @override
  Future<Tag?> getById(String id);
  @override
  Future<void> insert(Tag tag);
  @override
  Future<void> update(Tag tag);
  @override
  Future<void> delete(String id);
}

abstract class ISettingsRepository {
  Future<void> set(String key, String value);
  Future<String?> get(String key);
  Future<void> delete(String key);
  Future<Map<String, String>> getAll();
}

abstract class IRepository {
  Future<void> clearHistory();
}

abstract class ITagIconRepository {
  Future<Map<String, IconData>> getAllIconDatas();
  Future<void> setIconDataForTag(String tagName, IconData iconData);
  Future<void> deleteIconDataForTag(String tagName);
}
