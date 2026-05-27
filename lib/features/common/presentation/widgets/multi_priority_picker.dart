import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';

class MultiPriorityPicker extends StatelessWidget {
  final Set<Priority> selected;
  final ValueChanged<Set<Priority>> onChanged;

  const MultiPriorityPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Priority.values.map((p) {
        final isSelected = selected.contains(p);
        return FilterChip(
          label: Text(p.label),
          selected: isSelected,
          onSelected: (bool value) {
            final newSelected = Set<Priority>.from(selected);
            if (value) {
              newSelected.add(p);
            } else {
              newSelected.remove(p);
            }
            onChanged(newSelected);
          },
          avatar: Icon(p.icon, size: 16, color: isSelected ? Colors.white : p.color),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          selectedColor: p.color.withAlpha(50),
          checkmarkColor: p.color,
          labelStyle: TextStyle(
            color: isSelected ? p.color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: isSelected ? BorderSide(color: p.color) : BorderSide(color: Theme.of(context).colorScheme.outline),
        );
      }).toList(),
    );
  }
}
