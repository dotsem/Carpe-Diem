import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;
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

        String labelText = tag.name;
        TextStyle labelStyle;
        Widget avatar;
        Color backgroundColor;
        BorderSide side;

        if (isIncluded) {
          labelText = '+ ${tag.name}';
          labelStyle = TextStyle(
            color: includedColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          );
          avatar = Icon(icon, size: 14, color: includedColor);
          backgroundColor = includedColor.withAlpha(30);
          side = BorderSide(color: includedColor);
        } else if (isExcluded) {
          labelText = '- ${tag.name}';
          labelStyle = TextStyle(
            color: excludedColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
          );
          avatar = Icon(icon, size: 14, color: excludedColor.withAlpha(100));
          backgroundColor = excludedColor.withAlpha(30);
          side = BorderSide(color: excludedColor);
        } else {
          labelStyle = TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          );
          avatar = Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
          backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
          side = BorderSide(color: Theme.of(context).colorScheme.outline);
        }

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

        return GestureDetector(
          onTap: () {
            if (interactionMethod == FilterInteractionMethod.cycle) {
              handleCycle();
            } else {
              handleLeftClick();
            }
          },
          onSecondaryTap: () {
            if (interactionMethod == FilterInteractionMethod.leftRightClick) {
              handleRightClick();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Chip(
              label: Text(labelText, style: labelStyle),
              avatar: avatar,
              backgroundColor: backgroundColor,
              side: side,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      },
    );
  }
}
