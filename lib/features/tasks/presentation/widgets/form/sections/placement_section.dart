import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/task_placement_selector.dart';
import 'package:flutter/material.dart';

class PlacementSection extends StatelessWidget {
  final TaskPlacement placement;
  final ValueChanged<TaskPlacement> onChanged;

  const PlacementSection({super.key, required this.placement, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      items: [
        SectionItem(
          icon: Icons.sort,
          title: 'Placement & Urgency',
          child: TaskPlacementSelector(mini: true, selected: placement, onChanged: (p) => onChanged(p)),
        ),
      ],
    );
  }
}
