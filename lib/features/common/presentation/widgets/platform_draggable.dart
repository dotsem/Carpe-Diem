import 'dart:io';

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
  final bool rootOverlay;

  const PlatformDraggable({
    super.key,
    required this.data,
    required this.child,
    required this.feedback,
    this.childWhenDragging,
    this.delay = const Duration(milliseconds: 150),
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.rootOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isAndroid) {
      return LongPressDraggable<T>(
        data: data,
        delay: delay ?? const Duration(milliseconds: 150),
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        rootOverlay: rootOverlay,
        child: child,
      );
    }

    return Draggable<T>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      rootOverlay: rootOverlay,
      child: child,
    );
  }
}
