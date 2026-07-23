import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskDropZoneWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final void Function(Task task, int newIndex) onDrop;
  final bool Function(Task)? canAccept;
  final void Function(bool)? onHover;

  const TaskDropZoneWrapper({
    super.key,
    required this.index,
    required this.child,
    required this.onDrop,
    this.canAccept,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: DragTarget<Task>(
                  onWillAcceptWithDetails: (details) {
                    onHover?.call(true);
                    return canAccept?.call(details.data) ?? true;
                  },
                  onLeave: (details) => onHover?.call(false),
                  onAcceptWithDetails: (details) {
                    onHover?.call(false);
                    onDrop(details.data, index);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return Container(
                      alignment: Alignment.topCenter,
                      child: isHovered
                          ? Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
              Expanded(
                child: DragTarget<Task>(
                  onWillAcceptWithDetails: (details) {
                    onHover?.call(true);
                    return canAccept?.call(details.data) ?? true;
                  },
                  onLeave: (details) => onHover?.call(false),
                  onAcceptWithDetails: (details) {
                    onHover?.call(false);
                    onDrop(details.data, index + 1);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return Container(
                      alignment: Alignment.bottomCenter,
                      child: isHovered
                          ? Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
