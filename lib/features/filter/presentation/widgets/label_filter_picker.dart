import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class LabelFilterPicker extends ConsumerWidget {
  final List<String> selectedLabelIds;
  final List<String> excludedLabelIds;
  final List<String> inheritedLabelIds;
  final ValueChanged<List<String>> onSelected;
  final ValueChanged<List<String>> onExcluded;
  final FilterInteractionMethod interactionMethod;

  const LabelFilterPicker({
    super.key,
    required this.selectedLabelIds,
    required this.excludedLabelIds,
    this.inheritedLabelIds = const [],
    required this.onSelected,
    required this.onExcluded,
    required this.interactionMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;

    return LabelPicker(
      selectedLabelIds: selectedLabelIds,
      inheritedLabelIds: inheritedLabelIds,
      onSelected: (_) {}, // Handled by custom chipBuilder below
      allowAdd: false,
      enableContextMenu: false,
      chipBuilder: (context, label, isSelected, isInherited, defaultChip) {
        final isIncluded = selectedLabelIds.contains(label.id) || isInherited;
        final isExcluded = excludedLabelIds.contains(label.id);

        String labelText = label.name;
        TextStyle labelStyle;
        Widget avatar;
        Color backgroundColor;
        BorderSide side;

        if (isIncluded) {
          labelText = '+ ${label.name}';
          labelStyle = TextStyle(color: includedColor, fontSize: 13, fontWeight: FontWeight.bold);
          avatar = CircleAvatar(backgroundColor: label.color, radius: 6);
          backgroundColor = includedColor.withAlpha(30);
          side = BorderSide(color: includedColor);
        } else if (isExcluded) {
          labelText = '- ${label.name}';
          labelStyle = TextStyle(
            color: excludedColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
          );
          avatar = CircleAvatar(backgroundColor: label.color.withAlpha(100), radius: 6);
          backgroundColor = excludedColor.withAlpha(30);
          side = BorderSide(color: excludedColor);
        } else {
          labelStyle = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
          avatar = CircleAvatar(backgroundColor: label.color, radius: 6);
          backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
          side = BorderSide(color: Theme.of(context).colorScheme.outline);
        }

        void handleCycle() {
          final newInc = List<String>.from(selectedLabelIds);
          final newExc = List<String>.from(excludedLabelIds);
          if (isIncluded) {
            newInc.remove(label.id);
            newExc.add(label.id);
          } else if (isExcluded) {
            newExc.remove(label.id);
          } else {
            newInc.add(label.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        void handleLeftClick() {
          final newInc = List<String>.from(selectedLabelIds);
          final newExc = List<String>.from(excludedLabelIds);
          if (isIncluded) {
            newInc.remove(label.id);
          } else {
            newExc.remove(label.id);
            newInc.add(label.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        void handleRightClick() {
          final newInc = List<String>.from(selectedLabelIds);
          final newExc = List<String>.from(excludedLabelIds);
          if (isExcluded) {
            newExc.remove(label.id);
          } else {
            newInc.remove(label.id);
            newExc.add(label.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        return GestureDetector(
          onTap: isInherited
              ? null
              : () {
                  if (interactionMethod == FilterInteractionMethod.cycle) {
                    handleCycle();
                  } else {
                    handleLeftClick();
                  }
                },
          // TODO: handle mobile long-press gestures in the future
          onSecondaryTap: isInherited
              ? null
              : () {
                  if (interactionMethod == FilterInteractionMethod.leftRightClick) {
                    handleRightClick();
                  }
                },
          child: MouseRegion(
            cursor: isInherited ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: Chip(
              label: Text(labelText, style: labelStyle),
              avatar: avatar,
              backgroundColor: backgroundColor,
              side: side,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      },
    );
  }
}
