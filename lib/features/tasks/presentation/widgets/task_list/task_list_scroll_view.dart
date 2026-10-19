import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/active_task_reorderable_list.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_done_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_reorder_corridor.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';

class TaskListScrollView extends ConsumerStatefulWidget {
  final List<TaskHierarchyNode> activeNodes;
  final List<Widget> activeWidgets;
  final List<Widget> doneWidgets;
  final int doneCount;
  final bool isDoneExpanded;
  final VoidCallback onToggleDone;
  final Set<String> selectedTaskIds;
  final bool isReorderEnabled;
  final bool isPlanView;
  final EdgeInsets padding;
  final ScrollController? scrollController;

  const TaskListScrollView({
    super.key,
    required this.activeNodes,
    required this.activeWidgets,
    required this.doneWidgets,
    required this.doneCount,
    required this.isDoneExpanded,
    required this.onToggleDone,
    this.selectedTaskIds = const {},
    this.isReorderEnabled = true,
    this.isPlanView = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.scrollController,
  });

  @override
  ConsumerState<TaskListScrollView> createState() => _TaskListScrollViewState();
}

class _TaskListScrollViewState extends ConsumerState<TaskListScrollView> {
  late final ScrollController _scrollController;
  bool _createdLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _createdLocalController = true;
    }
  }

  @override
  void dispose() {
    if (_createdLocalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleDrop(Task task, int newIndex) {
    TaskReorderUtils.dispatchReorder(
      notifier: ref.read(taskProvider.notifier),
      nodes: widget.activeNodes,
      draggedTask: task,
      newIndex: newIndex,
      selectedTaskIds: widget.selectedTaskIds.toSet(),
      settings: ref.read(settingsProvider),
      isPlanView: widget.isPlanView,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TaskReorderScope(
      nodes: widget.activeNodes,
      isPlanView: widget.isPlanView,
      onDrop: _handleDrop,
      child: TaskReorderCorridor(
        scrollController: _scrollController,
        nodes: widget.activeNodes,
        padding: widget.padding,
        onDrop: _handleDrop,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: widget.padding.copyWith(top: 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (widget.activeNodes.isNotEmpty) ...[
                    _TaskTopDropZone(height: widget.padding.top),
                    ActiveTaskReorderableList(
                      nodes: widget.activeNodes,
                      widgets: widget.activeWidgets,
                      selectedTaskIds: widget.selectedTaskIds,
                      isReorderEnabled: widget.isReorderEnabled,
                      isPlanView: widget.isPlanView,
                      onReorder: (task, newSortOrder) => ref
                          .read(taskProvider.notifier)
                          .reorderTask(
                            task,
                            newSortOrder,
                            isPlanOrder: widget.isPlanView,
                          ),
                      onMultiReorder: (newSortOrders) => ref
                          .read(taskProvider.notifier)
                          .bulkReorderTasks(
                            newSortOrders,
                            isPlanOrder: widget.isPlanView,
                          ),
                    ),
                  ] else ...[
                    SizedBox(height: widget.padding.top),
                  ],
                  if (widget.doneCount > 0) ...[
                    TaskListDoneSection(
                      count: widget.doneCount,
                      isExpanded: widget.isDoneExpanded,
                      onToggle: widget.onToggleDone,
                      children: widget.doneWidgets,
                    ),
                  ],
                ]),
              ),
            ),
            if (widget.activeNodes.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const TaskEmptySpaceDropZone(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTopDropZone extends StatelessWidget {
  final double height;

  const _TaskTopDropZone({this.height = 16.0});

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    if (scope == null) return SizedBox(height: height);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        scope.onHoverSlot(details.data, 0);
        return true;
      },
      onLeave: (_) => scope.onLeaveSlot(),
      onAcceptWithDetails: (details) => scope.drop(details.data, 0),
      builder: (context, _, _) =>
          SizedBox(height: height, width: double.infinity),
    );
  }
}
