import 'package:carpe_diem/features/labels/presentation/widgets/add_label_dialog.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';

class LabelPicker extends ConsumerWidget {
  final List<String> selectedLabelIds;
  final List<String> inheritedLabelIds;
  final ValueChanged<List<String>> onSelected;
  final bool allowAdd;
  final bool isManageMode;

  const LabelPicker({
    super.key,
    required this.selectedLabelIds,
    this.inheritedLabelIds = const [],
    required this.onSelected,
    this.allowAdd = true,
    this.isManageMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(labelProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...provider.labels.map((label) {
          final isInherited = inheritedLabelIds.contains(label.id);
          final isSelected = selectedLabelIds.contains(label.id) || isInherited;

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

          Widget chip = FilterChip(
            label: Text(label.name),
            selected: isSelected,
            onSelected: isInherited
                ? null
                : (selected) {
                    final newIds = List<String>.from(selectedLabelIds);
                    if (selected) {
                      newIds.add(label.id);
                    } else {
                      newIds.remove(label.id);
                    }
                    onSelected(newIds);
                  },
            avatar: CircleAvatar(backgroundColor: label.color, radius: 6),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            selectedColor: isInherited ? label.color.withAlpha(100) : label.color.withAlpha(200),
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
      ],
    );
  }

  void _showAddLabel(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddLabelDialog());
  }
}
