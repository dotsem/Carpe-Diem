import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class SecondaryClickDragCanceller {
  bool _active = false;
  int? _dragPointerId;
  final VoidCallback? onCancel;

  SecondaryClickDragCanceller({this.onCancel});

  static SecondaryClickDragCanceller start({VoidCallback? onCancel}) {
    final canceller = SecondaryClickDragCanceller(onCancel: onCancel);
    canceller._attach();
    return canceller;
  }

  void _attach() {
    if (!_active) {
      _active = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    }
  }

  void dispose() {
    if (_active) {
      _active = false;
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
    }
  }

  void _handlePointer(PointerEvent event) {
    if (!_active) return;

    if (_dragPointerId == null && (event.buttons & kPrimaryMouseButton) != 0) {
      _dragPointerId = event.pointer;
    }

    if ((event.buttons & kSecondaryMouseButton) != 0) {
      final pointerToCancel = _dragPointerId ?? event.pointer;
      dispose();
      onCancel?.call();
      GestureBinding.instance.handlePointerEvent(
        PointerCancelEvent(
          pointer: pointerToCancel,
          kind: event.kind,
          device: event.device,
          position: event.position,
        ),
      );
      return;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_dragPointerId == null || event.pointer == _dragPointerId) {
        dispose();
      }
    }
  }
}
