import 'package:carpe_diem/features/common/presentation/widgets/multi_select_searchable_dropdown.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/add_tag_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/manageable_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagPicker extends ConsumerWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onSelected;
  final bool allowAdd;
  final bool isManageMode;
  final bool enableContextMenu;
  final bool isDropdown;
  final Widget Function(
    BuildContext context,
    Tag tag,
    bool isSelected,
    Widget defaultChip,
  )?
  chipBuilder;

  const TagPicker({
    super.key,
    required this.selectedTagIds,
    required this.onSelected,
    this.allowAdd = true,
    this.isManageMode = false,
    this.enableContextMenu = true,
    this.isDropdown = false,
    this.chipBuilder,
  });

  void _toggleTag(String id, bool select) {
    final newIds = List<String>.from(selectedTagIds);
    if (select) {
      if (!newIds.contains(id)) newIds.add(id);
    } else {
      newIds.remove(id);
    }
    onSelected(newIds);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(tagProvider);
    final tagIcons = ref.watch(tagIconProvider);
    final allTags = provider.tags;

    if (isManageMode || !isDropdown) {
      return _buildWrap(context, ref, allTags, tagIcons);
    }

    final selectedTags = allTags.where((t) => selectedTagIds.contains(t.id)).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...selectedTags.map((tag) => _buildSingleChip(context, ref, tag, tagIcons)),
        MultiSelectSearchableDropdown<Tag>(
          items: allTags,
          selectedIds: selectedTagIds,
          idGetter: (t) => t.id,
          nameGetter: (t) => t.name,
          leadingBuilder: (t) => Icon(tagIcons[t.name.trim().toLowerCase()] ?? Icons.tag, size: 16),
          onChanged: onSelected,
          buttonLabel: '+ Tag',
          searchHint: 'Search tags...',
          allowAdd: allowAdd,
          addNewLabel: 'New Tag',
          onAddNew: () => _showAddTag(context),
        ),
      ],
    );
  }

  Widget _buildWrap(BuildContext context, WidgetRef ref, List<Tag> tags, Map<String, IconData> tagIcons) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.map((tag) => _buildSingleChip(context, ref, tag, tagIcons)),
        if (allowAdd)
          ActionChip(
            label: const Text('New Tag'),
            avatar: const Icon(Icons.add, size: 16),
            onPressed: () => _showAddTag(context),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }

  Widget _buildSingleChip(BuildContext context, WidgetRef ref, Tag tag, Map<String, IconData> tagIcons) {
    final isSelected = selectedTagIds.contains(tag.id);
    final icon = tagIcons[tag.name.trim().toLowerCase()] ?? Icons.tag;

    if (isManageMode) {
      return ManageableChip(
        label: tag.name,
        avatar: Icon(icon),
        onTap: (details, box) {
          showTagContextMenu(
            context,
            ref,
            tag,
            details.localPosition,
            box,
          );
        },
      );
    }

    final Widget defaultChip = FilterChip(
      label: Text(tag.name),
      selected: isSelected,
      onSelected: (selected) => _toggleTag(tag.id, selected),
      avatar: Icon(icon),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    final Widget chip = chipBuilder != null
        ? chipBuilder!(context, tag, isSelected, defaultChip)
        : defaultChip;

    if (enableContextMenu) {
      return Builder(
        builder: (context) => GestureDetector(
          onSecondaryTapDown: (details) {
            showTagContextMenu(
              context,
              ref,
              tag,
              details.localPosition,
              context.findRenderObject() as RenderBox,
            );
          },
          child: chip,
        ),
      );
    } else {
      return chip;
    }
  }

  void _showAddTag(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddTagDialog());
  }
}



