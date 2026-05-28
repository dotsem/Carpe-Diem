import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';

class PriorityPicker extends StatelessWidget {
  final Priority selected;
  final ValueChanged<Priority> onChanged;

  const PriorityPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Priority.values.map((p) {
        final isSelected = p == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p.label),
            selected: isSelected,
            onSelected: (_) => onChanged(p),
            avatar: Icon(p.icon, size: 16, color: isSelected ? Colors.white : p.color),
            selectedColor: p.color,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}
