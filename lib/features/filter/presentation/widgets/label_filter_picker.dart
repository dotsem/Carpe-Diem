import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/common/tri_state_filter_chip.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return LabelPicker(
      selectedLabelIds: selectedLabelIds,
      inheritedLabelIds: inheritedLabelIds,
      onSelected: (_) {},
      allowAdd: false,
      enableContextMenu: false,
      chipBuilder: (context, label, isSelected, isInherited, defaultChip) {
        final isIncluded = selectedLabelIds.contains(label.id) || isInherited;
        final isExcluded = excludedLabelIds.contains(label.id);

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

        return TriStateFilterChip(
          label: label.name,
          isIncluded: isIncluded,
          isExcluded: isExcluded,
          isInherited: isInherited,
          avatar: CircleAvatar(
            backgroundColor: isExcluded
                ? label.color.withAlpha(100)
                : label.color,
            radius: 6,
          ),
          interactionMethod: interactionMethod,
          onCycle: handleCycle,
          onLeftClick: handleLeftClick,
          onRightClick: handleRightClick,
        );
      },
    );
  }
}
