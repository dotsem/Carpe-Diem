import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/common/tri_state_filter_chip.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagFilterPicker extends ConsumerWidget {
  final List<String> selectedTagIds;
  final List<String> excludedTagIds;
  final ValueChanged<List<String>> onSelected;
  final ValueChanged<List<String>> onExcluded;
  final FilterInteractionMethod interactionMethod;

  const TagFilterPicker({
    super.key,
    required this.selectedTagIds,
    required this.excludedTagIds,
    required this.onSelected,
    required this.onExcluded,
    required this.interactionMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagIcons = ref.watch(tagIconProvider);

    return TagPicker(
      selectedTagIds: selectedTagIds,
      onSelected: (_) {},
      allowAdd: false,
      enableContextMenu: false,
      chipBuilder: (context, tag, isSelected, defaultChip) {
        final isIncluded = selectedTagIds.contains(tag.id);
        final isExcluded = excludedTagIds.contains(tag.id);
        final icon = tagIcons[tag.name.trim().toLowerCase()] ?? Icons.tag;

        void handleCycle() {
          final newInc = List<String>.from(selectedTagIds);
          final newExc = List<String>.from(excludedTagIds);
          if (isIncluded) {
            newInc.remove(tag.id);
            newExc.add(tag.id);
          } else if (isExcluded) {
            newExc.remove(tag.id);
          } else {
            newInc.add(tag.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        void handleLeftClick() {
          final newInc = List<String>.from(selectedTagIds);
          final newExc = List<String>.from(excludedTagIds);
          if (isIncluded) {
            newInc.remove(tag.id);
          } else {
            newExc.remove(tag.id);
            newInc.add(tag.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        void handleRightClick() {
          final newInc = List<String>.from(selectedTagIds);
          final newExc = List<String>.from(excludedTagIds);
          if (isExcluded) {
            newExc.remove(tag.id);
          } else {
            newInc.remove(tag.id);
            newExc.add(tag.id);
          }
          onSelected(newInc);
          onExcluded(newExc);
        }

        return TriStateFilterChip(
          label: tag.name,
          isIncluded: isIncluded,
          isExcluded: isExcluded,
          avatar: Icon(
            icon,
            size: 14,
            color: isIncluded || isExcluded
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
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
