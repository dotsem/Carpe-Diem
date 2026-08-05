import 'package:carpe_diem/features/common/presentation/widgets/multi_select_searchable_dropdown.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/dialogs/add_label_dialog.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/manageable_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';

class LabelPicker extends ConsumerWidget {
  final List<String> selectedLabelIds;
  final List<String> inheritedLabelIds;
  final ValueChanged<List<String>> onSelected;
  final bool allowAdd;
  final bool isManageMode;
  final bool enableContextMenu;
  final bool isDropdown;
  final Widget Function(
    BuildContext context,
    Label label,
    bool isSelected,
    bool isInherited,
    Widget defaultChip,
  )?
  chipBuilder;

  const LabelPicker({
    super.key,
    required this.selectedLabelIds,
    this.inheritedLabelIds = const [],
    required this.onSelected,
    this.allowAdd = true,
    this.isManageMode = false,
    this.enableContextMenu = true,
    this.isDropdown = false,
    this.chipBuilder,
  });

  void _toggleLabel(String id, bool select) {
    final newIds = List<String>.from(selectedLabelIds);
    if (select) {
      if (!newIds.contains(id)) newIds.add(id);
    } else {
      newIds.remove(id);
    }
    onSelected(newIds);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(labelProvider);
    final allLabels = provider.labels;

    if (isManageMode || !isDropdown) {
      return _buildWrap(context, ref, allLabels);
    }

    final selectedAndInherited = allLabels.where((label) {
      return selectedLabelIds.contains(label.id) ||
          inheritedLabelIds.contains(label.id);
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...selectedAndInherited.map((label) => _buildSingleChip(context, ref, label)),
        MultiSelectSearchableDropdown<Label>(
          items: allLabels,
          selectedIds: selectedLabelIds,
          disabledIds: inheritedLabelIds,
          idGetter: (l) => l.id,
          nameGetter: (l) => l.name,
          leadingBuilder: (l) => CircleAvatar(backgroundColor: l.color, radius: 5),
          onChanged: onSelected,
          buttonLabel: '+ Label',
          searchHint: 'Search labels...',
          allowAdd: allowAdd,
          addNewLabel: 'New Label',
          onAddNew: () => _showAddLabel(context),
        ),
      ],
    );
  }

  Widget _buildWrap(BuildContext context, WidgetRef ref, List<Label> labels) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...labels.map((label) => _buildSingleChip(context, ref, label)),
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

  Widget _buildSingleChip(BuildContext context, WidgetRef ref, Label label) {
    final isInherited = inheritedLabelIds.contains(label.id);
    final isSelected = selectedLabelIds.contains(label.id) || isInherited;

    if (isManageMode) {
      return ManageableChip(
        label: label.name,
        avatar: CircleAvatar(backgroundColor: label.color, radius: 6),
        onTap: (details, box) {
          showLabelContextMenu(
            context,
            ref,
            label,
            details.localPosition,
            box,
          );
        },
      );
    }

    final Widget defaultChip = FilterChip(
      label: Text(label.name),
      selected: isSelected,
      onSelected: isInherited
          ? null
          : (selected) => _toggleLabel(label.id, selected),
      avatar: CircleAvatar(backgroundColor: label.color, radius: 6),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      selectedColor: isInherited
          ? label.color.withAlpha(100)
          : label.color.withAlpha(200),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    final Widget chip = chipBuilder != null
        ? chipBuilder!(
            context,
            label,
            isSelected,
            isInherited,
            defaultChip,
          )
        : defaultChip;

    final Widget tooltipChip = isInherited
        ? Tooltip(message: 'Inherited from project', child: chip)
        : chip;

    if (enableContextMenu) {
      return Builder(
        builder: (context) => GestureDetector(
          onSecondaryTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            showLabelContextMenu(
              context,
              ref,
              label,
              details.localPosition,
              box,
            );
          },
          child: tooltipChip,
        ),
      );
    } else {
      return tooltipChip;
    }
  }

  void _showAddLabel(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddLabelDialog());
  }
}



