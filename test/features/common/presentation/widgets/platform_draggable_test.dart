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

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('draggable_item')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(dragStarted, isTrue);
      expect(find.text('feedback'), findsOneWidget);

      final secondaryGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryGesture.addPointer(location: const Offset(100, 100));
      await secondaryGesture.down(const Offset(100, 100));
      await tester.pump();

      expect(endDetails, isNotNull);
      expect(endDetails!.wasAccepted, isFalse);
      expect(find.text('feedback'), findsNothing);

      await gesture.removePointer();
      await secondaryGesture.removePointer();
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

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('draggable_item')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      final secondaryGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryGesture.addPointer(location: const Offset(100, 100));
      await secondaryGesture.down(const Offset(100, 100));
      await tester.pump();

      expect(endDetails, isNull);
      expect(find.text('feedback'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      expect(endDetails, isNotNull);

      await gesture.removePointer();
      await secondaryGesture.removePointer();
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

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('draggable_item')),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(50, 50));
        await tester.pump();

        expect(find.text('unmounted_state'), findsOneWidget);
        expect(find.text('feedback'), findsOneWidget);

        final secondaryGesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await secondaryGesture.addPointer(location: const Offset(100, 100));
        await secondaryGesture.down(const Offset(100, 100));
        await tester.pump();

        expect(find.text('feedback'), findsNothing);

        await gesture.removePointer();
        await secondaryGesture.removePointer();
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

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('draggable_item')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);
      expect(cancelCalled, isFalse);

      final secondaryGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryGesture.addPointer(location: const Offset(100, 100));
      await secondaryGesture.down(const Offset(100, 100));
      await tester.pump();

      expect(cancelCalled, isTrue);
      expect(find.text('feedback'), findsNothing);

      await gesture.removePointer();
      await secondaryGesture.removePointer();
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

      final primaryGesture = await tester.startGesture(
        tester.getCenter(find.text('draggable_item')),
        kind: PointerDeviceKind.mouse,
      );
      await primaryGesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      final secondTouch = await tester.startGesture(
        const Offset(200, 200),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      await secondTouch.up();
      await tester.pump();

      expect(find.text('feedback'), findsOneWidget);

      final secondaryGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryGesture.addPointer(location: const Offset(100, 100));
      await secondaryGesture.down(const Offset(100, 100));
      await tester.pump();

      expect(cancelCalled, isTrue);
      expect(find.text('feedback'), findsNothing);

      await primaryGesture.removePointer();
      await secondTouch.removePointer();
      await secondaryGesture.removePointer();
    });
  });
}
