import 'package:flutter/material.dart';

class DraggableTaskTile extends StatelessWidget {
  final int index;
  final Widget child;
  final bool enableDrag;

  const DraggableTaskTile({
    required this.index,
    required this.child,
    super.key,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableDrag) return child;
    return ReorderableDelayedDragStartListener(index: index, child: child);
  }
}
