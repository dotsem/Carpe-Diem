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
      List<String> tagIds = const [],
    }) {
      return Task(
        id: id,
        title: 'Task $id',
        isUrgent: isUrgent,
        projectId: projectId,
        labelIds: labelIds,
        tagIds: tagIds,
        createdAt: now,
      );
    }

    Project createProject({required String id, bool isUrgent = false, List<String> labelIds = const []}) {
      return Project(
        id: id,
        name: 'Project $id',
        color: Colors.blue,
        isUrgent: isUrgent,
        labelIds: labelIds,
        createdAt: now,
      );
    }

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
      const incFilter = TaskFilter(projectIdsIncluded: {'p1', 'p2'});
      final taskInP1 = createTask(id: '1', projectId: 'p1');
      final taskInP3 = createTask(id: '2', projectId: 'p3');
      final taskNoProject = createTask(id: '3', projectId: null);

      expect(incFilter.applyToTask(taskInP1, []), isTrue);
      expect(incFilter.applyToTask(taskInP3, []), isFalse);
      expect(incFilter.applyToTask(taskNoProject, []), isFalse);

      const excFilter = TaskFilter(projectIdsExcluded: {'p3'});
      expect(excFilter.applyToTask(taskInP1, []), isTrue);
      expect(excFilter.applyToTask(taskInP3, []), isFalse);
      expect(excFilter.applyToTask(taskNoProject, []), isTrue);

      const comboFilter = TaskFilter(projectIdsIncluded: {'p1', 'p3'}, projectIdsExcluded: {'p3'});
      expect(comboFilter.applyToTask(taskInP1, []), isTrue);
      expect(comboFilter.applyToTask(taskInP3, []), isFalse);
    });

    test('applyToTask label matching handles inclusion, exclusion, and inheritance correctly', () {
      const incFilter = TaskFilter(labelIdsIncluded: {'l1'});
      final taskWithL1 = createTask(id: '1', labelIds: ['l1']);
      final taskWithL2 = createTask(id: '2', labelIds: ['l2']);
      final taskWithNoLabels = createTask(id: '3', labelIds: []);

      expect(incFilter.applyToTask(taskWithL1, []), isTrue);
      expect(incFilter.applyToTask(taskWithL2, []), isFalse);
      expect(incFilter.applyToTask(taskWithNoLabels, ['l1']), isTrue);
      expect(incFilter.applyToTask(taskWithNoLabels, ['l2']), isFalse);

      const excFilter = TaskFilter(labelIdsExcluded: {'l2'});
      expect(excFilter.applyToTask(taskWithL1, []), isTrue);
      expect(excFilter.applyToTask(taskWithL2, []), isFalse);
      expect(excFilter.applyToTask(taskWithNoLabels, ['l2']), isFalse);

      const comboFilter = TaskFilter(labelIdsIncluded: {'l1', 'l2'}, labelIdsExcluded: {'l2'});
      expect(comboFilter.applyToTask(taskWithL1, []), isTrue);
      expect(comboFilter.applyToTask(taskWithL2, []), isFalse);
    });

    test('applyToTask tag matching handles inclusion and exclusion correctly', () {
      const incFilter = TaskFilter(tagIdsIncluded: {'t1'});
      final taskWithT1 = createTask(id: '1', tagIds: ['t1']);
      final taskWithT2 = createTask(id: '2', tagIds: ['t2']);

      expect(incFilter.applyToTask(taskWithT1, []), isTrue);
      expect(incFilter.applyToTask(taskWithT2, []), isFalse);

      const excFilter = TaskFilter(tagIdsExcluded: {'t2'});
      expect(excFilter.applyToTask(taskWithT1, []), isTrue);
      expect(excFilter.applyToTask(taskWithT2, []), isFalse);

      const comboFilter = TaskFilter(tagIdsIncluded: {'t1', 't2'}, tagIdsExcluded: {'t2'});
      expect(comboFilter.applyToTask(taskWithT1, []), isTrue);
      expect(comboFilter.applyToTask(taskWithT2, []), isFalse);
    });

    test('applyToProject matches correctly based on priority and labels (inc/exc)', () {
      const filter = TaskFilter(isUrgent: true, labelIdsIncluded: {'l1'}, labelIdsExcluded: {'l2'});
      final matchProject = createProject(id: 'p1', isUrgent: true, labelIds: ['l1']);
      final wrongPriority = createProject(id: 'p2', isUrgent: false, labelIds: ['l1']);
      final wrongLabel = createProject(id: 'p3', isUrgent: true, labelIds: []);
      final excludedLabel = createProject(id: 'p4', isUrgent: true, labelIds: ['l1', 'l2']);

      expect(filter.applyToProject(matchProject), isTrue);
      expect(filter.applyToProject(wrongPriority), isFalse);
      expect(filter.applyToProject(wrongLabel), isFalse);
      expect(filter.applyToProject(excludedLabel), isFalse);
    });
  });
}
