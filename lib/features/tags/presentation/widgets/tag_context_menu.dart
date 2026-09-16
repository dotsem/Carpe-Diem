import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/context_menu_item_tile.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/edit_tag_dialog.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showTagContextMenu(
  BuildContext context,
  WidgetRef ref,
  Tag tag,
  Offset localPosition,
  RenderBox renderBox,
) {
  final provider = ref.read(tagProvider.notifier);
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset position = renderBox.localToGlobal(
    localPosition,
    ancestor: overlay,
  );

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        onTap: () => showDialog(
          context: context,
          builder: (context) => EditTagDialog(tag: tag),
        ),
        child: const ContextMenuItemTile(
          leading: Icon(Icons.edit),
          title: 'Edit',
        ),
      ),
      PopupMenuItem(
        onTap: () => showDialog(
          context: context,
          builder: (context) => DeleteDialog(
            title: 'Delete tag',
            message: 'Are you sure you want to delete "${tag.name}"?',
            onConfirm: () => provider.deleteTag(tag.id),
          ),
        ),
        child: const ContextMenuItemTile(
          leading: Icon(Icons.delete),
          title: 'Delete',
          color: AppColors.error,
        ),
      ),
    ],
  );
}
