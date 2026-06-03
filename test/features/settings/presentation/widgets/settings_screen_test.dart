import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/settings/presentation/screens/settings_screen.dart';

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockProjectRepository extends Mock implements IProjectRepository {}

class MockLabelRepository extends Mock implements ILabelRepository {}

void main() {
  group('SettingsScreen Widget Test', () {
    late MockSettingsRepository mockSettingsRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;

    setUp(() {
      mockSettingsRepo = MockSettingsRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
    });

    testWidgets('should render Settings Screen sections and fields correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            projectRepositoryProvider.overrideWithValue(mockProjectRepo),
            labelRepositoryProvider.overrideWithValue(mockLabelRepo),
          ],
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );

      // Trigger initialization and loaders
      await tester.pumpAndSettle();

      // Verify page titles
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your application preferences'), findsOneWidget);

      // Verify Appearance section and its tiles
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Compact Mode'), findsOneWidget);

      // Verify Labels section
      final labelsSection = find.text('LABELS');
      await tester.scrollUntilVisible(labelsSection, 200.0, scrollable: find.byType(Scrollable));
      expect(labelsSection, findsOneWidget);

      // Verify Planning section and its tiles
      final planningSection = find.text('PLANNING');
      await tester.scrollUntilVisible(planningSection, 200.0, scrollable: find.byType(Scrollable));
      expect(planningSection, findsOneWidget);

      final pickRandomTaskTile = find.text('Pick Random Task');
      await tester.scrollUntilVisible(pickRandomTaskTile, 200.0, scrollable: find.byType(Scrollable));
      expect(pickRandomTaskTile, findsOneWidget);

      // Verify Tasks section
      final tasksSection = find.text('TASKS');
      await tester.scrollUntilVisible(tasksSection, 200.0, scrollable: find.byType(Scrollable));
      expect(tasksSection, findsOneWidget);
    });
  });
}
