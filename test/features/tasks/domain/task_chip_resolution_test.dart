import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/task_chip_resolution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = {
  'task': Label(id: 'task', name: 'Task', color: Colors.blue),
  'shared': Label(id: 'shared', name: 'Shared', color: Colors.green),
  'project': Label(id: 'project', name: 'Project', color: Colors.red),
};
const _tags = {
  'one': Tag(id: 'one', name: 'One'),
  'two': Tag(id: 'two', name: 'Two'),
};

Task _task({List<String> labelIds = const [], List<String> tagIds = const []}) {
  return Task(
    id: 'task-id',
    title: 'Task',
    createdAt: DateTime(2026),
    labelIds: labelIds,
    tagIds: tagIds,
  );
}

Project _project(List<String> labelIds) => Project(
  id: 'project-id',
  name: 'Project',
  color: Colors.purple,
  createdAt: DateTime(2026),
  labelIds: labelIds,
);

void main() {
  group('resolveTaskChips', () {
    test('merges project and task labels without duplicates', () {
      final chips = resolveTaskChips(
        task: _task(labelIds: const ['task', 'shared']),
        project: _project(const ['shared', 'project']),
        labelLookup: (id) => _labels[id],
        tagLookup: (id) => _tags[id],
      );

      expect(chips.labels.map((label) => label.id), [
        'task',
        'shared',
        'project',
      ]);
    });

    test('resolves a task without a project', () {
      final chips = resolveTaskChips(
        task: _task(labelIds: const ['task'], tagIds: const ['one', 'two']),
        labelLookup: (id) => _labels[id],
        tagLookup: (id) => _tags[id],
      );

      expect(chips.labels, [_labels['task']]);
      expect(chips.tags, [_tags['one'], _tags['two']]);
    });

    test('drops label and tag ids missing from the lookups', () {
      final chips = resolveTaskChips(
        task: _task(
          labelIds: const ['missing', 'task'],
          tagIds: const ['missing', 'one'],
        ),
        project: _project(const ['also-missing']),
        labelLookup: (id) => _labels[id],
        tagLookup: (id) => _tags[id],
      );

      expect(chips.labels, [_labels['task']]);
      expect(chips.tags, [_tags['one']]);
    });
  });
}
