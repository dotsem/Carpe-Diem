import 'package:carpe_diem/features/tasks/data/models/task.dart';

abstract class TaskHierarchyNode {
  final int depth;
  const TaskHierarchyNode(this.depth);
}

class TaskNode extends TaskHierarchyNode {
  final Task task;
  final bool isBundledUnderParent;
  const TaskNode(this.task, int depth, {this.isBundledUnderParent = false})
    : super(depth);
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
