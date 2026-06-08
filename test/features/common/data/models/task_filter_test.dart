import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';

void main() {
  group('common', () {
    final now = DateTime.now();

    Task createTask({
      required String id,
      Priority priority = Priority.medium,
      String? projectId,
      List<String> labelIds = const [],
    }) {
      return Task(
        id: id,
        title: 'Task $id',
        priority: priority,
        projectId: projectId,
        labelIds: labelIds,
        createdAt: now,
      );
    }

    Project createProject({
      required String id,
      Priority priority = Priority.medium,
      List<String> labelIds = const [],
    }) {
      return Project(
        id: id,
        name: 'Project $id',
        color: Colors.blue,
        priority: priority,
        labelIds: labelIds,
        createdAt: now,
      );
    }

    test('TaskFilter is empty by default and matches matches/checks correctly', () {
      const filter = TaskFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.hasPriorityFilter, isFalse);
      expect(filter.hasProjectFilter, isFalse);
      expect(filter.hasLabelFilter, isFalse);

      const priorityFilter = TaskFilter(priorities: {Priority.high});
      expect(priorityFilter.isEmpty, isFalse);
      expect(priorityFilter.hasPriorityFilter, isTrue);

      const projectFilter = TaskFilter(projectIds: {'p1'});
      expect(projectFilter.isEmpty, isFalse);
      expect(projectFilter.hasProjectFilter, isTrue);

      const labelFilter = TaskFilter(labelIds: {'l1'});
      expect(labelFilter.isEmpty, isFalse);
      expect(labelFilter.hasLabelFilter, isTrue);
    });

    test('applyToTask matches correctly when filter is empty', () {
      const filter = TaskFilter();
      final task = createTask(id: '1');
      expect(filter.applyToTask(task, []), isTrue);
    });

    test('applyToTask matches priority filter', () {
      const filter = TaskFilter(priorities: {Priority.high, Priority.urgent});

      final highTask = createTask(id: '1', priority: Priority.high);
      final urgentTask = createTask(id: '2', priority: Priority.urgent);
      final lowTask = createTask(id: '3', priority: Priority.low);

      expect(filter.applyToTask(highTask, []), isTrue);
      expect(filter.applyToTask(urgentTask, []), isTrue);
      expect(filter.applyToTask(lowTask, []), isFalse);
    });

    test('applyToTask matches project filter and rejects null project task', () {
      const filter = TaskFilter(projectIds: {'p1', 'p2'});

      final taskInP1 = createTask(id: '1', projectId: 'p1');
      final taskInP3 = createTask(id: '2', projectId: 'p3');
      final taskNoProject = createTask(id: '3', projectId: null);

      expect(filter.applyToTask(taskInP1, []), isTrue);
      expect(filter.applyToTask(taskInP3, []), isFalse);
      expect(filter.applyToTask(taskNoProject, []), isFalse);
    });

    test('applyToTask matches label filter including inherited labels', () {
      const filter = TaskFilter(labelIds: {'l1'});

      final taskWithL1 = createTask(id: '1', labelIds: ['l1']);
      final taskWithL2 = createTask(id: '2', labelIds: ['l2']);
      final taskWithNoLabels = createTask(id: '3', labelIds: []);

      expect(filter.applyToTask(taskWithL1, []), isTrue);
      expect(filter.applyToTask(taskWithL2, []), isFalse);

      // Matches when label is inherited (e.g. from parent project/task)
      expect(filter.applyToTask(taskWithNoLabels, ['l1']), isTrue);
      expect(filter.applyToTask(taskWithNoLabels, ['l2']), isFalse);
    });

    test('applyToProject matches correctly based on empty, priority, or labels', () {
      const filter = TaskFilter(priorities: {Priority.medium}, labelIds: {'l1'});

      final matchProject = createProject(id: 'p1', priority: Priority.medium, labelIds: ['l1']);
      final wrongPriority = createProject(id: 'p2', priority: Priority.high, labelIds: ['l1']);
      final wrongLabel = createProject(id: 'p3', priority: Priority.medium, labelIds: ['l2']);

      expect(filter.applyToProject(matchProject), isTrue);
      expect(filter.applyToProject(wrongPriority), isFalse);
      expect(filter.applyToProject(wrongLabel), isFalse);
    });

    test('copyWith updates fields correctly or defaults to current values', () {
      const filter = TaskFilter(priorities: {Priority.low});
      final copied = filter.copyWith(projectIds: {'p1'});

      expect(copied.priorities, {Priority.low});
      expect(copied.projectIds, {'p1'});
      expect(copied.labelIds, isEmpty);
    });

    test('limitTo limits constraints appropriately', () {
      const filter = TaskFilter(priorities: {Priority.high}, projectIds: {'p1'}, labelIds: {'l1'});

      final limitPriorityOnly = filter.limitTo(projects: false, labels: false);
      expect(limitPriorityOnly.priorities, {Priority.high});
      expect(limitPriorityOnly.projectIds, isEmpty);
      expect(limitPriorityOnly.labelIds, isEmpty);
    });
  });
}
