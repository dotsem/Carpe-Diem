import 'package:carpe_diem/features/labels/presentation/widgets/dialogs/add_label_dialog.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

class LabelPicker extends ConsumerWidget {
  final List<String> selectedLabelIds;
  final List<String> excludedLabelIds;
  final List<String> inheritedLabelIds;
  final ValueChanged<List<String>> onSelected;
  final ValueChanged<List<String>>? onExcluded;
  final bool allowAdd;
  final bool isManageMode;
  final FilterInteractionMethod interactionMethod;

  const LabelPicker({
    super.key,
    required this.selectedLabelIds,
    this.excludedLabelIds = const [],
    this.inheritedLabelIds = const [],
    required this.onSelected,
    this.onExcluded,
    this.allowAdd = true,
    this.isManageMode = false,
    this.interactionMethod = FilterInteractionMethod.cycle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(labelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...provider.labels.map((label) {
          final isInherited = inheritedLabelIds.contains(label.id);
          final isIncluded = selectedLabelIds.contains(label.id) || isInherited;
          final isExcluded = excludedLabelIds.contains(label.id);

          if (isManageMode) {
            return Builder(
              builder: (context) {
                return ActionChip(
                  label: Text(label.name),
                  avatar: CircleAvatar(backgroundColor: label.color, radius: 6),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  side: BorderSide.none,
                  onPressed: () {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    showLabelContextMenu(context, ref, label, Offset.zero, box);
                  },
                );
              },
            );
          }

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

          final canExclude = onExcluded != null;

          void handleCycle() {
            final newInc = List<String>.from(selectedLabelIds);
            final newExc = List<String>.from(excludedLabelIds);
            if (isIncluded) {
              newInc.remove(label.id);
              if (canExclude) {
                newExc.add(label.id);
              }
            } else if (isExcluded) {
              newExc.remove(label.id);
            } else {
              newInc.add(label.id);
            }
            onSelected(newInc);
            if (canExclude) {
              onExcluded!(newExc);
            }
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
            if (canExclude) {
              onExcluded!(newExc);
            }
          }

          void handleRightClick() {
            if (!canExclude) return;
            final newInc = List<String>.from(selectedLabelIds);
            final newExc = List<String>.from(excludedLabelIds);
            if (isExcluded) {
              newExc.remove(label.id);
            } else {
              newInc.remove(label.id);
              newExc.add(label.id);
            }
            onSelected(newInc);
            onExcluded!(newExc);
          }

          Widget chip = GestureDetector(
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

          return Builder(
            builder: (context) => GestureDetector(
              onSecondaryTapDown: (details) {
                showLabelContextMenu(
                  context,
                  ref,
                  label,
                  details.localPosition,
                  context.findRenderObject() as RenderBox,
                );
              },
              child: isInherited ? Tooltip(message: 'Inherited from project', child: chip) : chip,
            ),
          );
        }),
        if (allowAdd)
          ActionChip(
            label: const Text('New Label'),
            avatar: const Icon(Icons.add, size: 16),
            onPressed: () => _showAddLabel(context),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }

  void _showAddLabel(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddLabelDialog());
  }
}
