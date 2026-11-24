import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('settings', () {
    late MockKeyValueRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockKeyValueRepository();
      container = ProviderContainer(
        overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default empty settings state', () {
      final state = container.read(settingsProvider);
      expect(state.compactMode, isFalse);
      expect(state.themeMode, equals(ThemeMode.system));
      expect(
        state.rightPanelPresentation,
        equals(RightPanelPresentation.overlay),
      );
    });

    test('should load settings from repository into state', () async {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => {
          'theme_mode': 'dark',
          'compact_mode': 'true',
          'right_panel_presentation': 'docked',
        },
      );

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeMode.dark));
      expect(state.compactMode, isTrue);
      expect(
        state.rightPanelPresentation,
        equals(RightPanelPresentation.docked),
      );
      verify(() => mockRepo.getAll()).called(1);
    });

    test(
      'should update setting in repository and trigger state mutation',
      () async {
        when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});

        final notifier = container.read(settingsProvider.notifier);
        await notifier.setThemeMode(ThemeMode.light);

        final state = container.read(settingsProvider);
        expect(state.themeMode, equals(ThemeMode.light));
        verify(() => mockRepo.set('theme_mode', 'light')).called(1);

        await notifier.setRightPanelPresentation(RightPanelPresentation.docked);
        expect(
          container.read(settingsProvider).rightPanelPresentation,
          equals(RightPanelPresentation.docked),
        );
        verify(
          () => mockRepo.set('right_panel_presentation', 'docked'),
        ).called(1);
      },
    );

    test('falls back to defaults when loading fails', () async {
      when(
        () => mockRepo.getAll(),
      ).thenThrow(StateError('database unavailable'));

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(settingsProvider).themeMode, ThemeMode.system);
    });

    test(
      'updates every supported setting and deletes default project',
      () async {
        when(() => mockRepo.set(any(), any())).thenAnswer((_) async {});
        when(() => mockRepo.delete(any())).thenAnswer((_) async {});
        final notifier = container.read(settingsProvider.notifier);

        await notifier.setMaxPlanningDays(14);
        await notifier.setFirstDayOfWeek(DateTime.sunday);
        await notifier.setTaskCompletionDelay(9);
        await notifier.setInheritParentDeadline(false);
        await notifier.setPrioritizeDeadlines(false);
        await notifier.setPrioritizeOverdue(true);
        await notifier.setInheritProjectDeadline(true);
        await notifier.setTaskGradientWidth(0.75);
        await notifier.setCompactMode(true);
        await notifier.setShowDescriptionOnCard(false);
        await notifier.setDefaultProjectId('project');
        await notifier.setHistoryRetention(30);
        await notifier.setDefaultStatsPeriod('monthly');
        await notifier.setShowActiveProjectsOnly(true);
        await notifier.setEnableRandomTask(true);
        await notifier.setFilterInteractionMethod(
          FilterInteractionMethod.leftRightClick,
        );
        await notifier.setPersistentFilter(true);
        await notifier.setTagAbsorption(Absorption.replace);
        await notifier.setKeepTagsInTitle(false);
        await notifier.setShowHashtagInTitle(true);
        await notifier.setReviewState(true);
        await notifier.setAnimationsEnabled(false);

        final state = container.read(settingsProvider);
        expect(state.maxPlanningDays, 14);
        expect(state.firstDayOfWeek, DateTime.sunday);
        expect(state.taskCompletionDelay, 9);
        expect(state.inheritParentDeadline, isFalse);
        expect(state.prioritizeDeadlines, isFalse);
        expect(state.prioritizeOverdue, isTrue);
        expect(state.inheritProjectDeadline, isTrue);
        expect(state.taskGradientWidth, 0.75);
        expect(state.compactMode, isTrue);
        expect(state.showDescriptionOnCard, isFalse);
        expect(state.defaultProjectId, 'project');
        expect(state.historyRetention, 30);
        expect(state.defaultStatsPeriod, 'monthly');
        expect(state.showActiveProjectsOnly, isTrue);
        expect(state.enableRandomTask, isTrue);
        expect(
          state.filterInteractionMethod,
          FilterInteractionMethod.leftRightClick,
        );
        expect(state.persistentFilter, isTrue);
        expect(state.tagAbsorption, Absorption.replace);
        expect(state.keepTagsInTitle, isFalse);
        expect(state.showHashtagInTitle, isTrue);
        expect(state.reviewState, isTrue);
        expect(state.animationsEnabled, isFalse);

        await notifier.setDefaultProjectId(null);
        expect(container.read(settingsProvider).defaultProjectId, isNull);
        verify(
          () => mockRepo.delete(SettingsConstants.keyDefaultProjectId),
        ).called(1);
      },
    );
  });
}
