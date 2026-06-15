import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

class MultiPriorityPicker extends StatelessWidget {
  final Set<Priority> included;
  final Set<Priority> excluded;
  final void Function(Set<Priority> included, Set<Priority> excluded) onChanged;
  final FilterInteractionMethod interactionMethod;

  const MultiPriorityPicker({
    super.key,
    required this.included,
    required this.excluded,
    required this.onChanged,
    required this.interactionMethod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final redColor = isDark ? Colors.redAccent : Colors.red.shade700;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Priority.values.map((p) {
        final isIncluded = included.contains(p);
        final isExcluded = excluded.contains(p);

        String labelText = p.label;
        TextStyle labelStyle;
        Color backgroundColor;
        BorderSide side;

        if (isIncluded) {
          labelText = '+ ${p.label}';
          labelStyle = TextStyle(color: greenColor, fontSize: 13, fontWeight: FontWeight.bold);
          backgroundColor = greenColor.withAlpha(30);
          side = BorderSide(color: greenColor);
        } else if (isExcluded) {
          labelText = '- ${p.label}';
          labelStyle = TextStyle(
            color: redColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
          );
          backgroundColor = redColor.withAlpha(30);
          side = BorderSide(color: redColor);
        } else {
          labelStyle = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
          backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
          side = BorderSide(color: Theme.of(context).colorScheme.outline);
        }

        void handleCycle() {
          final newInc = Set<Priority>.from(included);
          final newExc = Set<Priority>.from(excluded);
          if (isIncluded) {
            newInc.remove(p);
            newExc.add(p);
          } else if (isExcluded) {
            newExc.remove(p);
          } else {
            newInc.add(p);
          }
          onChanged(newInc, newExc);
        }

        void handleLeftClick() {
          final newInc = Set<Priority>.from(included);
          final newExc = Set<Priority>.from(excluded);
          if (isIncluded) {
            newInc.remove(p);
          } else {
            newExc.remove(p);
            newInc.add(p);
          }
          onChanged(newInc, newExc);
        }

        void handleRightClick() {
          final newInc = Set<Priority>.from(included);
          final newExc = Set<Priority>.from(excluded);
          if (isExcluded) {
            newExc.remove(p);
          } else {
            newInc.remove(p);
            newExc.add(p);
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
              avatar: Icon(p.icon, color: p.color, size: 16),
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
