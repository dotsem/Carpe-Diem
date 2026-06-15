import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';

void main() {
  group('filter', () {
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

    test('TaskFilter is empty by default and identifies constraints correctly', () {
      const filter = TaskFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.hasPriorityFilter, isFalse);
      expect(filter.hasProjectFilter, isFalse);
      expect(filter.hasLabelFilter, isFalse);

      const priorityIncFilter = TaskFilter(prioritiesIncluded: {Priority.high});
      expect(priorityIncFilter.isEmpty, isFalse);
      expect(priorityIncFilter.hasPriorityFilter, isTrue);

      const priorityExcFilter = TaskFilter(prioritiesExcluded: {Priority.high});
      expect(priorityExcFilter.isEmpty, isFalse);
      expect(priorityExcFilter.hasPriorityFilter, isTrue);

      const projectIncFilter = TaskFilter(projectIdsIncluded: {'p1'});
      expect(projectIncFilter.isEmpty, isFalse);
      expect(projectIncFilter.hasProjectFilter, isTrue);

      const projectExcFilter = TaskFilter(projectIdsExcluded: {'p1'});
      expect(projectExcFilter.isEmpty, isFalse);
      expect(projectExcFilter.hasProjectFilter, isTrue);

      const labelIncFilter = TaskFilter(labelIdsIncluded: {'l1'});
      expect(labelIncFilter.isEmpty, isFalse);
      expect(labelIncFilter.hasLabelFilter, isTrue);

      const labelExcFilter = TaskFilter(labelIdsExcluded: {'l1'});
      expect(labelExcFilter.isEmpty, isFalse);
      expect(labelExcFilter.hasLabelFilter, isTrue);
    });

    test('applyToTask matches correctly when filter is empty', () {
      const filter = TaskFilter();
      final task = createTask(id: '1');
      expect(filter.applyToTask(task, []), isTrue);
    });

    test('applyToTask priority matching handles inclusion and exclusion correctly', () {
      // Priority Inclusion Filter
      const incFilter = TaskFilter(prioritiesIncluded: {Priority.high, Priority.urgent});
      final highTask = createTask(id: '1', priority: Priority.high);
      final urgentTask = createTask(id: '2', priority: Priority.urgent);
      final lowTask = createTask(id: '3', priority: Priority.low);

      expect(incFilter.applyToTask(highTask, []), isTrue);
      expect(incFilter.applyToTask(urgentTask, []), isTrue);
      expect(incFilter.applyToTask(lowTask, []), isFalse);

      // Priority Exclusion Filter
      const excFilter = TaskFilter(prioritiesExcluded: {Priority.low});
      expect(excFilter.applyToTask(highTask, []), isTrue);
      expect(excFilter.applyToTask(urgentTask, []), isTrue);
      expect(excFilter.applyToTask(lowTask, []), isFalse);

      // Priority Inlusion and Exclusion combination (Exclusion takes precedence)
      const comboFilter = TaskFilter(
        prioritiesIncluded: {Priority.high, Priority.urgent},
        prioritiesExcluded: {Priority.high},
      );
      expect(comboFilter.applyToTask(highTask, []), isFalse); // High is excluded, so false
      expect(comboFilter.applyToTask(urgentTask, []), isTrue);  // Urgent is included, true
      expect(comboFilter.applyToTask(lowTask, []), isFalse);    // Low not in included set, false
    });

    test('applyToTask project matching handles inclusion and exclusion correctly', () {
      // Project Inclusion Filter
      const incFilter = TaskFilter(projectIdsIncluded: {'p1', 'p2'});
      final taskInP1 = createTask(id: '1', projectId: 'p1');
      final taskInP3 = createTask(id: '2', projectId: 'p3');
      final taskNoProject = createTask(id: '3', projectId: null);

      expect(incFilter.applyToTask(taskInP1, []), isTrue);
      expect(incFilter.applyToTask(taskInP3, []), isFalse);
      expect(incFilter.applyToTask(taskNoProject, []), isFalse);

      // Project Exclusion Filter
      const excFilter = TaskFilter(projectIdsExcluded: {'p3'});
      expect(excFilter.applyToTask(taskInP1, []), isTrue);
      expect(excFilter.applyToTask(taskInP3, []), isFalse);
      expect(excFilter.applyToTask(taskNoProject, []), isTrue); // No project task doesn't match excluded project ID p3

      // Project combo
      const comboFilter = TaskFilter(
        projectIdsIncluded: {'p1', 'p3'},
        projectIdsExcluded: {'p3'},
      );
      expect(comboFilter.applyToTask(taskInP1, []), isTrue);
      expect(comboFilter.applyToTask(taskInP3, []), isFalse); // p3 is excluded, so false
    });

    test('applyToTask label matching handles inclusion, exclusion, and inheritance correctly', () {
      // Label Inclusion Filter
      const incFilter = TaskFilter(labelIdsIncluded: {'l1'});
      final taskWithL1 = createTask(id: '1', labelIds: ['l1']);
      final taskWithL2 = createTask(id: '2', labelIds: ['l2']);
      final taskWithNoLabels = createTask(id: '3', labelIds: []);

      expect(incFilter.applyToTask(taskWithL1, []), isTrue);
      expect(incFilter.applyToTask(taskWithL2, []), isFalse);
      expect(incFilter.applyToTask(taskWithNoLabels, ['l1']), isTrue); // Inherited L1
      expect(incFilter.applyToTask(taskWithNoLabels, ['l2']), isFalse);

      // Label Exclusion Filter
      const excFilter = TaskFilter(labelIdsExcluded: {'l2'});
      expect(excFilter.applyToTask(taskWithL1, []), isTrue);
      expect(excFilter.applyToTask(taskWithL2, []), isFalse);
      expect(excFilter.applyToTask(taskWithNoLabels, ['l2']), isFalse); // Excluded label is inherited

      // Label Combo
      const comboFilter = TaskFilter(
        labelIdsIncluded: {'l1', 'l2'},
        labelIdsExcluded: {'l2'},
      );
      expect(comboFilter.applyToTask(taskWithL1, []), isTrue);
      expect(comboFilter.applyToTask(taskWithL2, []), isFalse); // L2 is excluded, so false
    });

    test('applyToProject matches correctly based on priority and labels (inc/exc)', () {
      const filter = TaskFilter(
        prioritiesIncluded: {Priority.medium},
        labelIdsIncluded: {'l1'},
        labelIdsExcluded: {'l2'},
      );

      final matchProject = createProject(id: 'p1', priority: Priority.medium, labelIds: ['l1']);
      final wrongPriority = createProject(id: 'p2', priority: Priority.high, labelIds: ['l1']);
      final wrongLabel = createProject(id: 'p3', priority: Priority.medium, labelIds: ['l3']);
      final excludedLabel = createProject(id: 'p4', priority: Priority.medium, labelIds: ['l1', 'l2']);

      expect(filter.applyToProject(matchProject), isTrue);
      expect(filter.applyToProject(wrongPriority), isFalse);
      expect(filter.applyToProject(wrongLabel), isFalse);
      expect(filter.applyToProject(excludedLabel), isFalse);
    });

    test('copyWith updates fields correctly or defaults to current values', () {
      const filter = TaskFilter(prioritiesIncluded: {Priority.low});
      final copied = filter.copyWith(projectIdsIncluded: {'p1'}, prioritiesExcluded: {Priority.high});

      expect(copied.prioritiesIncluded, {Priority.low});
      expect(copied.projectIdsIncluded, {'p1'});
      expect(copied.prioritiesExcluded, {Priority.high});
      expect(copied.labelIdsIncluded, isEmpty);
    });

    test('limitTo limits constraints appropriately', () {
      const filter = TaskFilter(
        prioritiesIncluded: {Priority.high},
        projectIdsIncluded: {'p1'},
        labelIdsIncluded: {'l1'},
        prioritiesExcluded: {Priority.low},
        projectIdsExcluded: {'p2'},
        labelIdsExcluded: {'l2'},
      );

      final limitPriorityOnly = filter.limitTo(projects: false, labels: false);
      expect(limitPriorityOnly.prioritiesIncluded, {Priority.high});
      expect(limitPriorityOnly.prioritiesExcluded, {Priority.low});
      expect(limitPriorityOnly.projectIdsIncluded, isEmpty);
      expect(limitPriorityOnly.projectIdsExcluded, isEmpty);
      expect(limitPriorityOnly.labelIdsIncluded, isEmpty);
      expect(limitPriorityOnly.labelIdsExcluded, isEmpty);
    });

    test('FilterInteractionMethod fromString works correctly', () {
      expect(FilterInteractionMethod.fromString('cycle'), FilterInteractionMethod.cycle);
      expect(FilterInteractionMethod.fromString('leftRightClick'), FilterInteractionMethod.leftRightClick);
      expect(FilterInteractionMethod.fromString('invalid_method'), FilterInteractionMethod.cycle);
    });
  });
}
