import 'package:flutter/material.dart';

/// Scrolls just far enough to make the fixed-extent item at [index] visible.
void ensureIndexVisible(
  ScrollController controller,
  int index,
  double itemExtent,
) {
  if (!controller.hasClients || index < 0) return;
  final itemTop = index * itemExtent;
  final itemBottom = itemTop + itemExtent;
  final scrollOffset = controller.offset;
  final viewport = controller.position.viewportDimension;

  if (itemBottom > scrollOffset + viewport) {
    controller.animateTo(
      (itemBottom - viewport).clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  } else if (itemTop < scrollOffset) {
    controller.animateTo(
      itemTop.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }
}
