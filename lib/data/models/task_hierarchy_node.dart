import 'package:carpe_diem/data/models/task.dart';

abstract class TaskHierarchyNode {
  final int depth;
  const TaskHierarchyNode(this.depth);
}

class TaskNode extends TaskHierarchyNode {
  final Task task;
  const TaskNode(this.task, int depth) : super(depth);
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
