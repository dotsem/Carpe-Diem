import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter/material.dart';

class TaskPlacementSelector extends StatelessWidget {
  final TaskPlacement selected;
  final ValueChanged<TaskPlacement> onChanged;

  const TaskPlacementSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TaskPlacement>(
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(value: TaskPlacement.bottom, label: Text('Bottom')),
        ButtonSegment(value: TaskPlacement.middle, label: Text('Middle')),
        ButtonSegment(value: TaskPlacement.top, label: Text('Top')),
        ButtonSegment(value: TaskPlacement.urgent, label: Text('Urgent')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
