import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';

class TaskHierarchyReorderUtils {
  static bool isPositionInGroup({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
    required SettingsState settings,
    bool isPlanView = false,
  }) => TaskReorderEngine.isPositionInGroup(
    draggedTask: draggedTask,
    targetIndex: targetIndex,
    nodes: nodes,
    settings: settings,
    isPlanView: isPlanView,
  );
}
