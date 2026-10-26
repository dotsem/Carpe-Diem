import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tasks', () {
    final now = DateTime.now();
    final task1 = Task(
      id: 't1',
      title: 'Task 1',
      sortOrder: 'a0',
      createdAt: now,
    );
    final task2 = Task(
      id: 't2',
      title: 'Task 2',
      sortOrder: 'a1',
      createdAt: now,
    );
    final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];

    testWidgets(
      'handleDragEnd does not execute fallback drop when isCancelled is true',
      (tester) async {
        int fallbackCount = 0;
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  home: Scaffold(
                    body: TaskReorderScope(
                      nodes: nodes,
                      onDrop: (_, _) {},
                      child: Builder(
                        builder: (innerContext) {
                          return ElevatedButton(
                            onPressed: () {
                              final scope = TaskReorderScope.of(innerContext);
                              scope?.onHoverSlot(task2, 0);
                              ref.read(taskDragProvider.notifier).cancelDrag();
                              tester.binding.scheduleFrame();
                            },
                            child: const Text('Cancel Drag'),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Cancel Drag'));
        await tester.pumpAndSettle();

        final scopeFinder = find.byType(Builder);
        final BuildContext innerContext = tester.element(scopeFinder.last);
        final scope = TaskReorderScope.of(innerContext);

        scope?.handleDragEnd(
          DraggableDetails(
            wasAccepted: false,
            velocity: Velocity.zero,
            offset: Offset.zero,
          ),
          onFallbackDrop: (_, _) => fallbackCount++,
        );

        expect(fallbackCount, equals(0));
        expect(container.read(taskDragProvider).isCancelled, isTrue);
      },
    );
  });
}
