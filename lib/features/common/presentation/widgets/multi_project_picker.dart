import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

class MultiProjectPicker extends ConsumerWidget {
  final Set<String> included;
  final Set<String> excluded;
  final void Function(Set<String> included, Set<String> excluded) onChanged;
  final FilterInteractionMethod interactionMethod;

  const MultiProjectPicker({
    super.key,
    required this.included,
    required this.excluded,
    required this.onChanged,
    required this.interactionMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(projectProvider);
    if (provider.projects.isEmpty) {
      return Center(
        child: Text(
          'No projects available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.projects.map((p) {
        final isIncluded = included.contains(p.id);
        final isExcluded = excluded.contains(p.id);

        String labelText = p.name;
        TextStyle labelStyle;
        Color backgroundColor;
        BorderSide side;

        if (isIncluded) {
          labelText = '+ ${p.name}';
          labelStyle = TextStyle(color: includedColor, fontSize: 13, fontWeight: FontWeight.bold);
          backgroundColor = includedColor.withAlpha(30);
          side = BorderSide(color: includedColor);
        } else if (isExcluded) {
          labelText = '- ${p.name}';
          labelStyle = TextStyle(
            color: excludedColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
          );
          backgroundColor = excludedColor.withAlpha(30);
          side = BorderSide(color: excludedColor);
        } else {
          labelStyle = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
          backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
          side = BorderSide(color: Theme.of(context).colorScheme.outline);
        }

        void handleCycle() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isIncluded) {
            newInc.remove(p.id);
            newExc.add(p.id);
          } else if (isExcluded) {
            newExc.remove(p.id);
          } else {
            newInc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        void handleLeftClick() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isIncluded) {
            newInc.remove(p.id);
          } else {
            newExc.remove(p.id);
            newInc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        void handleRightClick() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isExcluded) {
            newExc.remove(p.id);
          } else {
            newInc.remove(p.id);
            newExc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        return GestureDetector(
          onTap: () {
            if (interactionMethod == FilterInteractionMethod.cycle) {
              handleCycle();
            } else {
              handleLeftClick();
            }
          },
          // TODO: handle mobile long-press gestures in the future
          onSecondaryTap: () {
            if (interactionMethod == FilterInteractionMethod.leftRightClick) {
              handleRightClick();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Chip(
              label: Text(labelText, style: labelStyle),
              avatar: CircleAvatar(backgroundColor: p.color, radius: 4),
              backgroundColor: backgroundColor,
              side: side,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      }).toList(),
    );
  }
}
