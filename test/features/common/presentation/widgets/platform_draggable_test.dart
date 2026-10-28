import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformDraggable', () {
    testWidgets('cancels drag on secondary mouse click when enabled', (
      tester,
    ) async {
      DraggableDetails? endDetails;
      bool dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformDraggable<String>(
              data: 'test_item',
              feedback: const Text('feedback'),
              onDragStarted: () => dragStarted = true,
              onDragEnd: (details) => endDetails = details,
              child: const Text('draggable_item'),
            ),
          ),
        ),
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(tester.getCenter(find.text('draggable_item'))),
      );
      await tester.sendEventToBinding(pointer.move(const Offset(50, 50)));
      await tester.pump();

      expect(dragStarted, isTrue);
      expect(find.text('feedback'), findsOneWidget);

      await tester.sendEventToBinding(
        pointer.move(
          const Offset(100, 100),
          buttons: kPrimaryMouseButton | kSecondaryMouseButton,
        ),
      );
      await tester.pump();

      expect(endDetails, isNotNull);
      expect(endDetails!.wasAccepted, isFalse);
      expect(find.text('feedback'), findsNothing);
    });

    testWidgets('does not cancel drag on secondary mouse click when disabled', (
      tester,
    ) async {
      DraggableDetails? endDetails;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformDraggable<String>(
              data: 'test_item',
              cancelOnSecondaryClick: false,
              feedback: const Text('feedback'),
              onDragEnd: (details) => endDetails = details,
              child: const Text('draggable_item'),
            ),
          ),
        ),
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(tester.getCenter(find.text('draggable_item'))),
      );
      await tester.sendEventToBinding(pointer.move(const Offset(50, 50)));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      await tester.sendEventToBinding(
        pointer.move(
          const Offset(100, 100),
          buttons: kPrimaryMouseButton | kSecondaryMouseButton,
        ),
      );
      await tester.pump();

      expect(endDetails, isNull);
      expect(find.text('feedback'), findsOneWidget);

      await tester.sendEventToBinding(pointer.up());
      await tester.pump();

      expect(endDetails, isNotNull);
    });

    testWidgets(
      'cancels drag on secondary mouse click even if widget was unmounted during drag',
      (tester) async {
        bool showDraggable = true;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, set) {
                  setState = set;
                  if (!showDraggable) {
                    return const Text('unmounted_state');
                  }
                  return PlatformDraggable<String>(
                    data: 'test_item',
                    feedback: const Text('feedback'),
                    onDragStarted: () {
                      setState(() => showDraggable = false);
                    },
                    child: const Text('draggable_item'),
                  );
                },
              ),
            ),
          ),
        );

        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(
          pointer.down(tester.getCenter(find.text('draggable_item'))),
        );
        await tester.sendEventToBinding(pointer.move(const Offset(50, 50)));
        await tester.pump();

        expect(find.text('unmounted_state'), findsOneWidget);
        expect(find.text('feedback'), findsOneWidget);

        await tester.sendEventToBinding(
          pointer.move(
            const Offset(100, 100),
            buttons: kPrimaryMouseButton | kSecondaryMouseButton,
          ),
        );
        await tester.pump();

        expect(find.text('feedback'), findsNothing);
      },
    );

    testWidgets('invokes onDragCancel callback on secondary mouse click', (
      tester,
    ) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformDraggable<String>(
              data: 'test_item',
              feedback: const Text('feedback'),
              onDragCancel: () => cancelCalled = true,
              child: const Text('draggable_item'),
            ),
          ),
        ),
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(tester.getCenter(find.text('draggable_item'))),
      );
      await tester.sendEventToBinding(pointer.move(const Offset(50, 50)));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);
      expect(cancelCalled, isFalse);

      await tester.sendEventToBinding(
        pointer.move(
          const Offset(100, 100),
          buttons: kPrimaryMouseButton | kSecondaryMouseButton,
        ),
      );
      await tester.pump();

      expect(cancelCalled, isTrue);
      expect(find.text('feedback'), findsNothing);
    });

    testWidgets('ignores unrelated pointer up event during drag session', (
      tester,
    ) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformDraggable<String>(
              data: 'test_item',
              feedback: const Text('feedback'),
              onDragCancel: () => cancelCalled = true,
              child: const Text('draggable_item'),
            ),
          ),
        ),
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(tester.getCenter(find.text('draggable_item'))),
      );
      await tester.sendEventToBinding(pointer.move(const Offset(50, 50)));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      final secondPointer = TestPointer(2, PointerDeviceKind.touch);
      await tester.sendEventToBinding(
        secondPointer.down(const Offset(200, 200)),
      );
      await tester.pump();
      await tester.sendEventToBinding(secondPointer.up());
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      await tester.sendEventToBinding(
        pointer.move(
          const Offset(100, 100),
          buttons: kPrimaryMouseButton | kSecondaryMouseButton,
        ),
      );
      await tester.pump();

      expect(cancelCalled, isTrue);
      expect(find.text('feedback'), findsNothing);
    });
  });
}
