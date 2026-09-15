import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskDropZoneScope extends StatefulWidget {
  final int urgentSectionEndIndex;
  final int itemCount;
  final Widget child;

  const TaskDropZoneScope({
    super.key,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    required this.child,
  });

  static TaskDropZoneScopeInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TaskDropZoneScopeInherited>();
  }

  @override
  State<TaskDropZoneScope> createState() => _TaskDropZoneScopeState();
}

class _TaskDropZoneScopeState extends State<TaskDropZoneScope> {
  final ValueNotifier<int?> _activeDropIndex = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _activeDropIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskDropZoneScopeInherited(
      activeDropIndexNotifier: _activeDropIndex,
      urgentSectionEndIndex: widget.urgentSectionEndIndex,
      itemCount: widget.itemCount,
      child: widget.child,
    );
  }
}

class TaskDropZoneScopeInherited extends InheritedWidget {
  final ValueNotifier<int?> activeDropIndexNotifier;
  final int urgentSectionEndIndex;
  final int itemCount;

  const TaskDropZoneScopeInherited({
    super.key,
    required this.activeDropIndexNotifier,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    required super.child,
  });

  int resolveEffectiveIndex(Task task, int rawIndex) {
    if (!task.isUrgent) {
      if (rawIndex < urgentSectionEndIndex) {
        return urgentSectionEndIndex;
      }
    } else {
      if (rawIndex > urgentSectionEndIndex) {
        return urgentSectionEndIndex;
      }
    }
    return rawIndex;
  }

  @override
  bool updateShouldNotify(TaskDropZoneScopeInherited oldWidget) {
    return activeDropIndexNotifier != oldWidget.activeDropIndexNotifier ||
        urgentSectionEndIndex != oldWidget.urgentSectionEndIndex ||
        itemCount != oldWidget.itemCount;
  }
}

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

  Widget _buildIndicator(
    BuildContext context,
    bool isHovered,
    Alignment alignment,
  ) {
    return Container(
      alignment: alignment,
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
  }

  @override
  Widget build(BuildContext context) {
    final scope = TaskDropZoneScope.of(context);

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
                    if (scope != null) {
                      final effectiveIndex = scope.resolveEffectiveIndex(
                        details.data,
                        index,
                      );
                      scope.activeDropIndexNotifier.value = effectiveIndex;
                    }
                    return canAccept?.call(details.data) ?? true;
                  },
                  onLeave: (details) {
                    onHover?.call(false);
                    if (scope != null) {
                      scope.activeDropIndexNotifier.value = null;
                    }
                  },
                  onAcceptWithDetails: (details) {
                    onHover?.call(false);
                    final targetIndex = scope != null
                        ? scope.resolveEffectiveIndex(details.data, index)
                        : index;
                    if (scope != null) {
                      scope.activeDropIndexNotifier.value = null;
                    }
                    onDrop(details.data, targetIndex);
                  },
                  builder: (context, candidateData, rejectedData) {
                    if (scope == null) {
                      return _buildIndicator(
                        context,
                        candidateData.isNotEmpty,
                        Alignment.topCenter,
                      );
                    }
                    return ValueListenableBuilder<int?>(
                      valueListenable: scope.activeDropIndexNotifier,
                      builder: (context, activeIndex, _) {
                        final isHovered = activeIndex == index;
                        return _buildIndicator(
                          context,
                          isHovered,
                          Alignment.topCenter,
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: DragTarget<Task>(
                  onWillAcceptWithDetails: (details) {
                    onHover?.call(true);
                    if (scope != null) {
                      final effectiveIndex = scope.resolveEffectiveIndex(
                        details.data,
                        index + 1,
                      );
                      scope.activeDropIndexNotifier.value = effectiveIndex;
                    }
                    return canAccept?.call(details.data) ?? true;
                  },
                  onLeave: (details) {
                    onHover?.call(false);
                    if (scope != null) {
                      scope.activeDropIndexNotifier.value = null;
                    }
                  },
                  onAcceptWithDetails: (details) {
                    onHover?.call(false);
                    final targetIndex = scope != null
                        ? scope.resolveEffectiveIndex(details.data, index + 1)
                        : index + 1;
                    if (scope != null) {
                      scope.activeDropIndexNotifier.value = null;
                    }
                    onDrop(details.data, targetIndex);
                  },
                  builder: (context, candidateData, rejectedData) {
                    if (scope == null) {
                      return _buildIndicator(
                        context,
                        candidateData.isNotEmpty,
                        Alignment.bottomCenter,
                      );
                    }
                    return ValueListenableBuilder<int?>(
                      valueListenable: scope.activeDropIndexNotifier,
                      builder: (context, activeIndex, _) {
                        final isHovered =
                            activeIndex == index + 1 &&
                            index == scope.itemCount - 1;
                        return _buildIndicator(
                          context,
                          isHovered,
                          Alignment.bottomCenter,
                        );
                      },
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
