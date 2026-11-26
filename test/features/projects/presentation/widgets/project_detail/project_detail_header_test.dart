import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mock_repositories.dart';

class _FakeProjectNotifier extends ProjectNotifier {
  final Project initial;

  _FakeProjectNotifier(this.initial);

  @override
  ProjectState build() => ProjectState(projects: [initial]);

  @override
  Future<void> deleteProject(Project project) async {
    state = const ProjectState();
  }
}

void main() {
  group('ProjectDetailHeader', () {
    testWidgets('deleting the project navigates back to the project list', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      // why: the test font draws every glyph full width, so menu labels overflow the 256px menu
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final project = Project(
        id: 'p1',
        name: 'Alpha',
        color: Colors.blue,
        createdAt: DateTime(2026),
      );
      final labelRepo = MockLabelRepository();
      when(labelRepo.getAll).thenAnswer((_) async => []);

      // why: like the real screen, the header disappears once the project is gone
      final router = GoRouter(
        initialLocation: '/projects/p1',
        routes: [
          GoRoute(
            path: '/projects',
            builder: (_, _) => const Text('project list'),
          ),
          GoRoute(
            path: '/projects/p1',
            builder: (_, _) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final current = ref.watch(projectProvider).getById('p1');
                  return current == null
                      ? const Text('Project not found')
                      : ProjectDetailHeader(project: current);
                },
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            labelRepositoryProvider.overrideWithValue(labelRepo),
            projectProvider.overrideWith(() => _FakeProjectNotifier(project)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Project'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('project list'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/projects');
    });
  });
}
