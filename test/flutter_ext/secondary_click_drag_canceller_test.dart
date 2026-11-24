import 'package:carpe_diem/flutter_ext/secondary_click_drag_canceller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void send(PointerEvent event) =>
      GestureBinding.instance.handlePointerEvent(event);

  testWidgets('cancels the drag once when the secondary button is pressed', (
    tester,
  ) async {
    var cancels = 0;
    final canceller = SecondaryClickDragCanceller.start(
      onCancel: () => cancels++,
    );
    addTearDown(canceller.dispose);

    send(const PointerDownEvent());
    send(
      const PointerMoveEvent(
        buttons: kPrimaryMouseButton | kSecondaryMouseButton,
      ),
    );
    send(
      const PointerMoveEvent(
        buttons: kPrimaryMouseButton | kSecondaryMouseButton,
      ),
    );

    expect(cancels, 1);
  });

  testWidgets('stops listening once the dragging pointer lifts', (
    tester,
  ) async {
    var cancels = 0;
    final canceller = SecondaryClickDragCanceller.start(
      onCancel: () => cancels++,
    );
    addTearDown(canceller.dispose);

    send(const PointerDownEvent());
    send(const PointerUpEvent());
    send(const PointerDownEvent(pointer: 2, buttons: kSecondaryMouseButton));

    expect(cancels, 0);
  });

  testWidgets('keeps listening when a different pointer lifts', (tester) async {
    var cancels = 0;
    final canceller = SecondaryClickDragCanceller.start(
      onCancel: () => cancels++,
    );
    addTearDown(canceller.dispose);

    send(const PointerDownEvent());
    send(const PointerDownEvent(pointer: 2));
    send(const PointerUpEvent(pointer: 2));
    send(
      const PointerMoveEvent(
        buttons: kPrimaryMouseButton | kSecondaryMouseButton,
      ),
    );

    expect(cancels, 1);
  });
}
