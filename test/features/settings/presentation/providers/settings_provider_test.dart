import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('settings', () {
    late MockSettingsRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockSettingsRepository();
      container = ProviderContainer(overrides: [settingsRepositoryProvider.overrideWithValue(mockRepo)]);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default empty settings state', () {
      final state = container.read(settingsProvider);
      expect(state.compactMode, isFalse);
      expect(state.themeMode, equals(ThemeMode.system));
      expect(state.taskLayout, equals(TaskLayout.list));
    });

    test('should load settings from repository into state', () async {
      when(
        () => mockRepo.getAll(),
      ).thenAnswer((_) async => {'theme_mode': 'dark', 'compact_mode': 'true', 'task_layout': 'kanban'});

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeMode.dark));
      expect(state.compactMode, isTrue);
      expect(state.taskLayout, equals(TaskLayout.kanban));
      verify(() => mockRepo.getAll()).called(1);
    });

    test('should update setting in repository and trigger state mutation', () async {
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);

      final state = container.read(settingsProvider);
      expect(state.themeMode, equals(ThemeMode.light));
      verify(() => mockRepo.set('theme_mode', 'light')).called(1);
    });
  });
}
