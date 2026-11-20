import 'package:flutter/material.dart';

class TaskHierarchyIndicator extends StatelessWidget {
  final int depth;
  final Widget child;

  const TaskHierarchyIndicator({
    required this.depth,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (depth == 0) return child;

    var current = child;
    for (var i = 0; i < depth; i++) {
      current = Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: current,
      );
    }

    return current;
  }
}
