import 'dart:io';

import 'package:dotmaterial/src/secondary_click_drag_canceller.dart';
import 'package:flutter/material.dart';

class PlatformDraggable<T extends Object> extends StatelessWidget {
  final T data;
  final Widget child;
  final Widget feedback;
  final Widget? childWhenDragging;
  final Duration? delay;
  final VoidCallback? onDragStarted;
  final DragUpdateCallback? onDragUpdate;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onDragCancel;
  final void Function(Velocity, Offset)? onDraggableCanceled;
  final bool rootOverlay;
  final bool cancelOnSecondaryClick;

  const PlatformDraggable({
    required this.data,
    required this.child,
    required this.feedback,
    super.key,
    this.childWhenDragging,
    this.delay = const Duration(milliseconds: 150),
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.onDraggableCanceled,
    this.rootOverlay = true,
    this.cancelOnSecondaryClick = true,
  });

  void _handleDragStarted() {
    if (cancelOnSecondaryClick) {
      SecondaryClickDragCanceller.start(onCancel: onDragCancel);
    }
    onDragStarted?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isAndroid) {
      // why: this mobile-only widget branch cannot execute on desktop CI.
      // coverage:ignore-start
      return LongPressDraggable<T>(
        data: data,
        delay: delay ?? const Duration(milliseconds: 150),
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: _handleDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        onDraggableCanceled: onDraggableCanceled,
        rootOverlay: rootOverlay,
        child: child,
      );
      // coverage:ignore-end
    }

    return Draggable<T>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      onDragStarted: _handleDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onDraggableCanceled: onDraggableCanceled,
      rootOverlay: rootOverlay,
      child: child,
    );
  }
}
