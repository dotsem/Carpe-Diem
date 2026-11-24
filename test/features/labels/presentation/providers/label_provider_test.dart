import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  late MockLabelRepository labels;
  late MockProjectRepository projects;
  late MockTaskRepository tasks;
  late MockKeyValueRepository settings;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      const Label(id: 'fallback', name: 'Fallback', color: Colors.transparent),
    );
  });

  setUp(() {
    labels = MockLabelRepository();
    projects = MockProjectRepository();
    tasks = MockTaskRepository();
    settings = MockKeyValueRepository();
    when(() => settings.getAll()).thenAnswer((_) async => {});
    when(() => labels.getById(any())).thenAnswer((_) async => null);
    when(() => projects.getAll()).thenAnswer((_) async => []);
    when(
      () => tasks.getByDate(
        any(),
        prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        prioritizeOverdue: any(named: 'prioritizeOverdue'),
      ),
    ).thenAnswer((_) async => []);
    when(() => tasks.getOverdue(any())).thenAnswer((_) async => []);
    when(
      () => tasks.getUnscheduled(
        prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        prioritizeOverdue: any(named: 'prioritizeOverdue'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => tasks.getAll(
        prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        prioritizeOverdue: any(named: 'prioritizeOverdue'),
      ),
    ).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [
        labelRepositoryProvider.overrideWithValue(labels),
        projectRepositoryProvider.overrideWithValue(projects),
        taskRepositoryProvider.overrideWithValue(tasks),
        keyValueRepositoryProvider.overrideWithValue(settings),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loads, adds, and finds labels', () async {
    const label = Label(id: 'label', name: 'Label', color: Colors.red);
    when(() => labels.getAll()).thenAnswer((_) async => [label]);
    when(() => labels.insert(any())).thenAnswer((_) async {});
    final notifier = container.read(labelProvider.notifier);

    await notifier.loadLabels();

    expect(notifier.getById('label'), label);
    expect(notifier.getById(null), isNull);
    expect(container.read(labelProvider).getById('missing'), isNull);
    expect(container.read(labelProvider).getById(null), isNull);
    await notifier.addLabel(name: 'Added', color: Colors.blue);
    verify(() => labels.insert(any())).called(1);
  });

  test('state copyWith preserves values and undo refreshes labels', () async {
    const label = Label(id: 'label', name: 'Label', color: Colors.red);
    expect(const LabelState(labels: [label]).copyWith().labels, [label]);
    when(() => labels.insert(any())).thenAnswer((_) async {});
    when(() => labels.delete(any())).thenAnswer((_) async {});
    when(() => labels.getAll()).thenAnswer((_) async => [label]);
    final notifier = container.read(labelProvider.notifier);

    await notifier.addLabel(name: 'Added', color: Colors.blue);
    await container.read(undoRedoProvider.notifier).undo();

    verify(() => labels.getAll()).called(2);
  });

  test('updates a label and refreshes dependent data', () async {
    const old = Label(id: 'label', name: 'Old', color: Colors.red);
    const updated = Label(id: 'label', name: 'New', color: Colors.blue);
    when(() => labels.getById('label')).thenAnswer((_) async => old);
    when(() => labels.update(updated)).thenAnswer((_) async {});
    when(() => labels.getAll()).thenAnswer((_) async => [updated]);

    await container.read(labelProvider.notifier).updateLabel(updated);

    verify(() => labels.update(updated)).called(1);
    verify(() => projects.getAll()).called(1);
    verify(() => tasks.getUnscheduled()).called(2);
  });

  test('ignores update and delete when label is missing', () async {
    const label = Label(id: 'missing', name: 'Missing', color: Colors.red);
    when(() => labels.getById('missing')).thenAnswer((_) async => null);
    final notifier = container.read(labelProvider.notifier);

    await notifier.updateLabel(label);
    await notifier.deleteLabel('missing');

    verifyNever(() => labels.update(any()));
    verifyNever(() => labels.delete(any()));
  });

  test('deletes label, removes filter, and refreshes data', () async {
    const label = Label(id: 'label', name: 'Label', color: Colors.red);
    when(() => labels.getById('label')).thenAnswer((_) async => label);
    when(() => labels.delete('label')).thenAnswer((_) async {});
    when(() => labels.getAll()).thenAnswer((_) async => []);
    container
        .read(filterProvider.notifier)
        .setFilter(const TaskFilter(labelIdsExcluded: {'label'}));

    await container.read(labelProvider.notifier).deleteLabel('label');

    verify(() => labels.delete('label')).called(1);
    expect(container.read(filterProvider).filter.labelIdsExcluded, isEmpty);
  });
}
