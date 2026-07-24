import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

import 'package:carpe_diem/features/projects/data/models/project.dart';

void main() {
  group('filter', () {
    final now = DateTime.now();

    Task createTask({
      required String id,
      bool isUrgent = false,
      String? projectId,
      List<String> labelIds = const [],
    }) {
      return Task(
        id: id,
        title: 'Task $id',
        isUrgent: isUrgent,
        projectId: projectId,
        labelIds: labelIds,
        createdAt: now,
      );
    }

    Project createProject({
      required String id,
      bool isUrgent = false,
      List<String> labelIds = const [],
    }) {
      return Project(
        id: id,
        name: 'Project $id',
        color: Colors.blue,
        isUrgent: isUrgent,
        labelIds: labelIds,
        createdAt: now,
      );
    }

    test('TaskFilter is empty by default and identifies constraints correctly', () {
      const filter = TaskFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.hasUrgencyFilter, isFalse);
      expect(filter.hasProjectFilter, isFalse);
      expect(filter.hasLabelFilter, isFalse);

      const priorityIncFilter = TaskFilter(isUrgent: true);
      expect(priorityIncFilter.isEmpty, isFalse);
      expect(priorityIncFilter.hasUrgencyFilter, isTrue);

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

    test('applyToTask urgency matching handles it correctly', () {
      const incFilter = TaskFilter(isUrgent: true);
      final highTask = createTask(id: '1', isUrgent: false);
      final urgentTask = createTask(id: '2', isUrgent: true);
      final lowTask = createTask(id: '3', isUrgent: false);

      expect(incFilter.applyToTask(highTask, []), isFalse);
      expect(incFilter.applyToTask(urgentTask, []), isTrue);
      expect(incFilter.applyToTask(lowTask, []), isFalse);
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
        isUrgent: true,
        labelIdsIncluded: {'l1'},
        labelIdsExcluded: {'l2'},
      );
      final matchProject = createProject(id: 'p1', isUrgent: true, labelIds: ['l1']);
      final wrongPriority = createProject(id: 'p2', isUrgent: false, labelIds: ['l1']);
      final wrongLabel = createProject(id: 'p3', isUrgent: true, labelIds: []);
      final excludedLabel = createProject(id: 'p4', isUrgent: true, labelIds: ['l1', 'l2']);

      expect(filter.applyToProject(matchProject), isTrue);
      expect(filter.applyToProject(wrongPriority), isFalse);
      expect(filter.applyToProject(wrongLabel), isFalse);
      expect(filter.applyToProject(excludedLabel), isFalse);
    });

    test('copyWith updates fields correctly or defaults to current values', () {
      const filter = TaskFilter(isUrgent: false);
      final copied = filter.copyWith(projectIdsIncluded: {'p1'}, clearIsUrgent: true);

      expect(copied.isUrgent, isNull);
      expect(copied.projectIdsIncluded, {'p1'});
      expect(copied.labelIdsIncluded, isEmpty);
    });

    test('limitTo limits constraints appropriately', () {
      const filter = TaskFilter(
        isUrgent: true,
        projectIdsIncluded: {'p1'},
        labelIdsIncluded: {'l1'},
        projectIdsExcluded: {'p2'},
        labelIdsExcluded: {'l2'},
      );

      final limitPriorityOnly = filter.limitTo(projects: false, labels: false);
      expect(limitPriorityOnly.isUrgent, true);
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
