import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemSizeTransitionBuilder extends ConsumerStatefulWidget {
  final bool isExpanded;
  final double width;
  final double narrowWidth;
  final bool isNarrow;
  final List<Task> doneTasks;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox)
  onContextMenu;
  final void Function(Task task) onEdit;
  final Map<String, FocusNode>? itemFocusNodes;
  final ScrollController scrollController;
  final bool forceExpanded;
  final bool isDraggingOver;
  final bool isTransitioning;
  final VoidCallback onToggle;
  final VoidCallback onDragEntering;
  final VoidCallback onDragExiting;

  const ItemSizeTransitionBuilder({
    super.key,
    required this.isExpanded,
    required this.width,
    required this.narrowWidth,
    required this.isNarrow,
    required this.doneTasks,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
    required this.itemFocusNodes,
    required this.scrollController,
    required this.forceExpanded,
    required this.isDraggingOver,
    required this.isTransitioning,
    required this.onToggle,
    required this.onDragEntering,
    required this.onDragExiting,
  });

  @override
  ConsumerState<ItemSizeTransitionBuilder> createState() =>
      _ItemSizeTransitionBuilderState();
}

class _ItemSizeTransitionBuilderState
    extends ConsumerState<ItemSizeTransitionBuilder> {
  bool _localTransitioning = false;

  @override
  void initState() {
    super.initState();
    _localTransitioning = widget.isTransitioning;
  }

  @override
  void didUpdateWidget(ItemSizeTransitionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransitioning != oldWidget.isTransitioning) {
      _localTransitioning = widget.isTransitioning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(
        end: widget.isExpanded ? widget.width : widget.narrowWidth,
      ),
      onEnd: () {
        if (mounted) setState(() => _localTransitioning = false);
      },
      builder: (context, width, child) {
        if (_localTransitioning &&
            widget.scrollController.hasClients &&
            widget.isExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients && _localTransitioning) {
              widget.scrollController.jumpTo(
                widget.scrollController.position.maxScrollExtent,
              );
            }
          });
        }

        return SizedBox(
          width: width,
          child: KanbanColumn(
            title: 'Done',
            titleColor: AppColors.success,
            tasks: widget.doneTasks,
            isNarrow: widget.isNarrow,
            acceptedStatus: TaskStatus.done,
            onStatusChange: widget.onStatusChange,
            onContextMenu: widget.onContextMenu,
            onEdit: widget.onEdit,
            itemFocusNodes: widget.itemFocusNodes,
            isCollapsed: !widget.isExpanded,
            onToggle: widget.onToggle,
            onDragEntering: widget.onDragEntering,
            onDragExiting: widget.onDragExiting,
          ),
        );
      },
    );
  }
}
