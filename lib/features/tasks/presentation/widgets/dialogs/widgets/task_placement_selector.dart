import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter/material.dart';

class TaskPlacementSelector extends StatelessWidget {
  final TaskPlacement? selected;
  final ValueChanged<TaskPlacement?> onChanged;

  /// [mini] only shows icons, useful for mobile interfaces
  final bool mini;

  const TaskPlacementSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TaskPlacement>(
      expandedInsets: EdgeInsets.zero,
      segments: mini
          ? [
              ButtonSegment(
                value: TaskPlacement.bottom,
                label: Icon(Icons.vertical_align_bottom),
                tooltip: TaskPlacement.bottom.name,
              ),
              ButtonSegment(
                value: TaskPlacement.middle,
                label: Icon(Icons.vertical_align_center),
                tooltip: TaskPlacement.middle.name,
              ),
              ButtonSegment(
                value: TaskPlacement.top,
                label: Icon(Icons.vertical_align_top),
                tooltip: TaskPlacement.top.name,
              ),
              ButtonSegment(
                value: TaskPlacement.urgent,
                label: Icon(
                  Icons.warning_amber_rounded,
                ), // TODO: replace everywhere with priority_high
                tooltip: TaskPlacement.urgent.name,
              ),
            ]
          : [
              ButtonSegment(
                value: TaskPlacement.bottom,
                label: Text(TaskPlacement.bottom.name),
              ),
              ButtonSegment(
                value: TaskPlacement.middle,
                label: Text(TaskPlacement.middle.name),
              ),
              ButtonSegment(
                value: TaskPlacement.top,
                label: Text(TaskPlacement.top.name),
              ),
              ButtonSegment(
                value: TaskPlacement.urgent,
                label: Text(TaskPlacement.urgent.name),
              ),
            ],
      selected: selected != null ? {selected!} : <TaskPlacement>{},
      emptySelectionAllowed: true,
      onSelectionChanged: (s) => onChanged(s.firstOrNull),
    );
  }
}
