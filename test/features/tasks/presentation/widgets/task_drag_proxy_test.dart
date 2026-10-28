import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskDragProxy', () {
    late TestTaskRepositories repos;
    final task = Task(
      id: 'task_pendulum_test',
      title: 'Pendulum Test Task',
      sortOrder: 'a0',
      createdAt: DateTime.now(),
    );

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    testWidgets('renders properly with elevated pivot transform', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskDragProxy(task: task, selectedCount: 1, width: 300),
            ),
          ),
        ),
      );

      expect(find.byType(BaseTaskCard), findsOneWidget);
      final transform = tester.widget<Transform>(
        find.byWidgetPredicate(
          (w) => w is Transform && w.alignment == const Alignment(0.0, -1.2),
        ),
      );
      expect(transform.transform, isNotNull);
    });

    testWidgets('responds to pointer move with dynamic rotation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskDragProxy(task: task, selectedCount: 1, width: 300),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 16));

      // Move rapidly to the right
      await gesture.moveTo(const Offset(350, 100));
      await tester.pump(const Duration(milliseconds: 32));

      // Allow pendulum simulation to oscillate and settle
      await tester.pumpAndSettle();

      expect(find.byType(TaskDragProxy), findsOneWidget);
      final dynamicTransform = tester.widget<Transform>(
        find.byWidgetPredicate(
          (w) => w is Transform && (w.alignment as Alignment?)?.y == -1.2,
        ),
      );
      final alignment = dynamicTransform.alignment as Alignment;
      expect(alignment.y, equals(-1.2));
      expect(alignment.x, isNotNull);
      await gesture.removePointer();
    });

    testWidgets('does not rotate when animations are disabled in settings', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...repos.providerOverrides,
            settingsProvider.overrideWith(
              () => _DisabledAnimationSettingsNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TaskDragProxy(task: task, selectedCount: 1, width: 300),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.moveTo(const Offset(350, 100));
      await tester.pump(const Duration(milliseconds: 32));

      final transform = tester.widget<Transform>(
        find.byWidgetPredicate(
          (w) => w is Transform && (w.alignment as Alignment?)?.y == -1.2,
        ),
      );
      expect(transform.transform, equals(Matrix4.identity()));
      await gesture.removePointer();
    });
  });
}

class _DisabledAnimationSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState({
      SettingsConstants.keyAnimationsEnabled: 'false',
    });
  }
}
