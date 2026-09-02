import 'package:carpe_diem/features/tasks/data/models/task.dart';

abstract class TaskHierarchyNode {
  final int depth;
  const TaskHierarchyNode(this.depth);

  Task? get task => null;
}

class TaskNode extends TaskHierarchyNode {
  @override
  final Task task;
  final bool isBundledUnderParent;
  const TaskNode(this.task, int depth, {this.isBundledUnderParent = false})
    : super(depth);
}

class ParentContainerNode extends TaskHierarchyNode {
  @override
  final Task task;
  final int totalSubtasks;
  final int completedSubtasks;
  final int plannedSubtasks;
  final bool hasUrgentChild;
  final bool isCollapsed;

  const ParentContainerNode({
    required this.task,
    required int depth,
    this.totalSubtasks = 0,
    this.completedSubtasks = 0,
    this.plannedSubtasks = 0,
    this.hasUrgentChild = false,
    this.isCollapsed = false,
  }) : super(depth);
}

class BlockerIndicatorNode extends TaskHierarchyNode {
  final String blockerId;
  final String blockerTitle;
  final String blockedTaskId;
  const BlockerIndicatorNode({
    required this.blockerId,
    required this.blockerTitle,
    required this.blockedTaskId,
    required int depth,
  }) : super(depth);
}
