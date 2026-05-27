import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MultiProjectPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const MultiProjectPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        if (provider.projects.isEmpty) {
          return Center(
            child: Text(
              'No projects available',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.projects.map((p) {
            final isSelected = selected.contains(p.id);
            return FilterChip(
              label: Text(p.name),
              selected: isSelected,
              onSelected: (bool value) {
                final newSelected = Set<String>.from(selected);
                if (value) {
                  newSelected.add(p.id);
                } else {
                  newSelected.remove(p.id);
                }
                onChanged(newSelected);
              },
              avatar: CircleAvatar(backgroundColor: p.color, radius: 4),
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
      },
    );
  }
}
