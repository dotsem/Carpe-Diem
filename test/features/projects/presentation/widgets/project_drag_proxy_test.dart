import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_drag_proxy.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('ProjectDragProxy', () {
    late TestTaskRepositories repos;
    final project = Project(
      id: 'proj_pendulum_test',
      name: 'Pendulum Test Project',
      color: Colors.blue,
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
            home: Scaffold(body: ProjectDragProxy(project: project)),
          ),
        ),
      );

      expect(find.byType(ProjectCard), findsOneWidget);
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
            home: Scaffold(body: ProjectDragProxy(project: project)),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.moveTo(const Offset(350, 100));
      await tester.pump(const Duration(milliseconds: 32));

      await tester.pumpAndSettle();

      expect(find.byType(ProjectDragProxy), findsOneWidget);
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
            home: Scaffold(body: ProjectDragProxy(project: project)),
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
