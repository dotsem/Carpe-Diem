import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/add_tag_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagPicker extends ConsumerWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onSelected;
  final bool allowAdd;
  final bool isManageMode;
  final bool enableContextMenu;
  final Widget Function(BuildContext context, Tag tag, bool isSelected, Widget defaultChip)? chipBuilder;

  const TagPicker({
    super.key,
    required this.selectedTagIds,
    required this.onSelected,
    this.allowAdd = true,
    this.isManageMode = false,
    this.enableContextMenu = true,
    this.chipBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(tagProvider);
    final tagIcons = ref.watch(tagIconProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...provider.tags.map((tag) {
          final isSelected = selectedTagIds.contains(tag.id);
          final icon = tagIcons[tag.name.trim().toLowerCase()] ?? Icons.tag;

          if (isManageMode) {
            return Builder(
              builder: (context) {
                return ActionChip(
                  label: Text(tag.name),
                  avatar: Icon(icon),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  side: BorderSide.none,
                  onPressed: () {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    showTagContextMenu(context, ref, tag, Offset.zero, box);
                  },
                );
              },
            );
          }

          final Widget defaultChip = FilterChip(
            label: Text(tag.name),
            selected: isSelected,
            onSelected: (selected) {
              final newIds = List<String>.from(selectedTagIds);
              if (selected) {
                newIds.add(tag.id);
              } else {
                newIds.remove(tag.id);
              }
              onSelected(newIds);
            },
            avatar: Icon(icon),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
          );

          final Widget chip = chipBuilder != null ? chipBuilder!(context, tag, isSelected, defaultChip) : defaultChip;

          if (enableContextMenu) {
            return Builder(
              builder: (context) => GestureDetector(
                onSecondaryTapDown: (details) {
                  showTagContextMenu(context, ref, tag, details.localPosition, context.findRenderObject() as RenderBox);
                },
                child: chip,
              ),
            );
          } else {
            return chip;
          }
        }),
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

  void _showAddTag(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddTagDialog());
  }
}
