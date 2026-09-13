import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('backlog_label_tab', () {
    const testLabel1 = Label(id: 'l1', name: 'Work', color: Color(0xFF00FF00));
    const testLabel2 = Label(
      id: 'l2',
      name: 'Personal',
      color: Color(0xFFFF0000),
    );
    final labels = [testLabel1, testLabel2];

    group('BacklogLabelTabState', () {
      test('fromString maps inbox, valid label, and fallback all', () {
        final inbox = BacklogLabelTabState.fromString('inbox');
        expect(inbox.scope, BacklogLabelTabScope.inbox);
        expect(inbox.labelId, isNull);

        final valid = BacklogLabelTabState.fromString(
          'l1',
          validLabelIds: {'l1', 'l2'},
        );
        expect(valid.scope, BacklogLabelTabScope.label);
        expect(valid.labelId, 'l1');

        final invalid = BacklogLabelTabState.fromString(
          'deleted',
          validLabelIds: {'l1', 'l2'},
        );
        expect(invalid.scope, BacklogLabelTabScope.all);
        expect(invalid.labelId, isNull);
      });

      test('getIndex returns correct tab indices', () {
        const allState = BacklogLabelTabState.all();
        expect(allState.getIndex(labels), 0);

        const inboxState = BacklogLabelTabState.inbox();
        expect(inboxState.getIndex(labels), labels.length + 1);

        const l1State = BacklogLabelTabState.label('l1');
        expect(l1State.getIndex(labels), 1);

        const l2State = BacklogLabelTabState.label('l2');
        expect(l2State.getIndex(labels), 2);

        const missingState = BacklogLabelTabState.label('nonexistent');
        expect(missingState.getIndex(labels), 0);
      });
    });

    group('BacklogLabelTabNotifier', () {
      late MockKeyValueRepository mockRepo;
      late MockLabelRepository mockLabelRepo;
      late ProviderContainer container;

      setUp(() {
        mockRepo = MockKeyValueRepository();
        mockLabelRepo = MockLabelRepository();
        when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});
        when(() => mockRepo.get(any())).thenAnswer((_) async => null);
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => labels);

        container = ProviderContainer(
          overrides: [
            keyValueRepositoryProvider.overrideWithValue(mockRepo),
            labelRepositoryProvider.overrideWithValue(mockLabelRepo),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('initial state is all', () {
        final state = container.read(backlogLabelTabProvider);
        expect(state.scope, BacklogLabelTabScope.all);
        expect(state.labelId, isNull);
      });

      test('select methods update state and auto-persist to repository', () {
        final notifier = container.read(backlogLabelTabProvider.notifier);

        notifier.selectLabel('l1');
        expect(
          container.read(backlogLabelTabProvider).scope,
          BacklogLabelTabScope.label,
        );
        expect(container.read(backlogLabelTabProvider).labelId, 'l1');
        verify(() => mockRepo.set(keyLastActiveTab, 'l1')).called(1);

        notifier.selectInbox();
        expect(
          container.read(backlogLabelTabProvider).scope,
          BacklogLabelTabScope.inbox,
        );
        verify(() => mockRepo.set(keyLastActiveTab, 'inbox')).called(1);

        notifier.selectAll();
        expect(
          container.read(backlogLabelTabProvider).scope,
          BacklogLabelTabScope.all,
        );
        verify(() => mockRepo.set(keyLastActiveTab, 'all')).called(1);
      });

      test('loadLastActiveTab restores valid label tab', () async {
        when(
          () => mockRepo.get(keyLastActiveTab),
        ).thenAnswer((_) async => 'l1');
        await container.read(labelProvider.notifier).loadLabels();

        await container
            .read(backlogLabelTabProvider.notifier)
            .loadLastActiveTab();

        final state = container.read(backlogLabelTabProvider);
        expect(state.scope, BacklogLabelTabScope.label);
        expect(state.labelId, 'l1');
      });

      test(
        'loadLastActiveTab falls back to all when label id is invalid',
        () async {
          when(
            () => mockRepo.get(keyLastActiveTab),
          ).thenAnswer((_) async => 'ghost_id');
          await container.read(labelProvider.notifier).loadLabels();

          await container
              .read(backlogLabelTabProvider.notifier)
              .loadLastActiveTab();

          final state = container.read(backlogLabelTabProvider);
          expect(state.scope, BacklogLabelTabScope.all);
        },
      );

      test('deleting active label resets state to all and persists', () async {
        await container.read(labelProvider.notifier).loadLabels();
        container.read(backlogLabelTabProvider.notifier).selectLabel('l1');

        when(
          () => mockLabelRepo.getAll(),
        ).thenAnswer((_) async => [testLabel2]);
        await container.read(labelProvider.notifier).loadLabels();

        final state = container.read(backlogLabelTabProvider);
        expect(state.scope, BacklogLabelTabScope.all);
        verify(
          () => mockRepo.set(keyLastActiveTab, 'all'),
        ).called(greaterThanOrEqualTo(1));
      });

      test(
        'excluding active label in filter resets state to all and persists',
        () async {
          await container.read(labelProvider.notifier).loadLabels();
          container.read(backlogLabelTabProvider.notifier).selectLabel('l1');

          container
              .read(filterProvider.notifier)
              .setFilter(const TaskFilter(labelIdsExcluded: {'l1'}));

          final state = container.read(backlogLabelTabProvider);
          expect(state.scope, BacklogLabelTabScope.all);
          verify(
            () => mockRepo.set(keyLastActiveTab, 'all'),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      test(
        'nextTab cycles forward through all -> l1 -> l2 -> inbox -> all',
        () async {
          await container.read(labelProvider.notifier).loadLabels();
          final notifier = container.read(backlogLabelTabProvider.notifier);

          notifier.nextTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.label,
          );
          expect(container.read(backlogLabelTabProvider).labelId, 'l1');

          notifier.nextTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.label,
          );
          expect(container.read(backlogLabelTabProvider).labelId, 'l2');

          notifier.nextTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.inbox,
          );

          notifier.nextTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.all,
          );
        },
      );

      test(
        'prevTab cycles backward through all -> inbox -> l2 -> l1 -> all',
        () async {
          await container.read(labelProvider.notifier).loadLabels();
          final notifier = container.read(backlogLabelTabProvider.notifier);

          notifier.prevTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.inbox,
          );

          notifier.prevTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.label,
          );
          expect(container.read(backlogLabelTabProvider).labelId, 'l2');

          notifier.prevTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.label,
          );
          expect(container.read(backlogLabelTabProvider).labelId, 'l1');

          notifier.prevTab();
          expect(
            container.read(backlogLabelTabProvider).scope,
            BacklogLabelTabScope.all,
          );
        },
      );

      test('nextTab skips labels excluded by filter', () async {
        await container.read(labelProvider.notifier).loadLabels();
        container
            .read(filterProvider.notifier)
            .setFilter(const TaskFilter(labelIdsExcluded: {'l1'}));
        final notifier = container.read(backlogLabelTabProvider.notifier);

        notifier.nextTab();
        expect(
          container.read(backlogLabelTabProvider).scope,
          BacklogLabelTabScope.label,
        );
        expect(container.read(backlogLabelTabProvider).labelId, 'l2');
      });
    });
  });
}
