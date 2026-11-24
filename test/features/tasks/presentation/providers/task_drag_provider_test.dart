import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tasks', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('startDrag updates draggedTaskId and resets cancellation', () {
      final notifier = container.read(taskDragProvider.notifier);
      notifier.startDrag('t1');

      final state = container.read(taskDragProvider);
      expect(state.draggedTaskId, equals('t1'));
      expect(state.isCancelled, isFalse);
    });

    test('cancelDrag sets isCancelled and clears draggedTaskId', () {
      final notifier = container.read(taskDragProvider.notifier);
      notifier.startDrag('t1');
      notifier.cancelDrag();

      final state = container.read(taskDragProvider);
      expect(state.draggedTaskId, isNull);
      expect(state.isCancelled, isTrue);
    });

    test('endDrag resets all state to idle defaults', () {
      final notifier = container.read(taskDragProvider.notifier);
      notifier.startDrag('t1');
      notifier.setValidTarget(true);
      notifier.setActiveScope('scope-1');
      notifier.endDrag();

      final state = container.read(taskDragProvider);
      expect(state.draggedTaskId, isNull);
      expect(state.hasValidTarget, isFalse);
      expect(state.activeScopeId, isNull);
      expect(state.isCancelled, isFalse);
    });

    test('state equality, hash, pointer offset, and scope clearing work', () {
      const first = TaskDragState(
        draggedTaskId: 'task',
        hasValidTarget: true,
        activeScopeId: 'scope',
      );
      const second = TaskDragState(
        draggedTaskId: 'task',
        hasValidTarget: true,
        activeScopeId: 'scope',
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);

      final notifier = container.read(taskDragProvider.notifier);
      notifier.updatePointerOffset(const Offset(3, 4));
      expect(notifier.pointerOffset, const Offset(3, 4));
      notifier.setValidTarget(true);
      notifier.setValidTarget(true);
      notifier.setActiveScope('scope');
      notifier.setActiveScope('scope');
      notifier.clearActiveScope('other');
      notifier.clearActiveScope('scope');
      expect(container.read(taskDragProvider).activeScopeId, isNull);
    });

    testWidgets(
      'right mouse button pointer event triggers cancelDrag and dispatches PointerCancelEvent',
      (tester) async {
        final notifier = container.read(taskDragProvider.notifier);
        notifier.startDrag('t1');

        var receivedCancelEvent = false;
        void testRoute(PointerEvent event) {
          if (event is PointerCancelEvent && event.pointer == 42) {
            receivedCancelEvent = true;
          }
        }

        GestureBinding.instance.pointerRouter.addRoute(42, testRoute);
        addTearDown(() {
          GestureBinding.instance.pointerRouter.removeRoute(42, testRoute);
        });

        await tester.sendEventToBinding(
          const PointerDownEvent(pointer: 42, kind: PointerDeviceKind.mouse),
        );
        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 42,
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton | kSecondaryMouseButton,
          ),
        );

        final state = container.read(taskDragProvider);
        expect(state.draggedTaskId, isNull);
        expect(state.isCancelled, isTrue);
        expect(receivedCancelEvent, isTrue);
      },
    );
  });
}
