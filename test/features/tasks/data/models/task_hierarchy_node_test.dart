import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TaskHierarchyNode has no task by default', () {
    const baseNode = _EmptyNode(0);
    expect(baseNode.task, isNull);
  });
}

class _EmptyNode extends TaskHierarchyNode {
  const _EmptyNode(super.depth);
}
