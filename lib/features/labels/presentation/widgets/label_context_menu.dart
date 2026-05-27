import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/delete_dialog.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/edit_label_dialog.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showLabelContextMenu(BuildContext context, WidgetRef ref, Label label, Offset localPosition, RenderBox renderBox) {
  final provider = ref.read(labelProvider.notifier);
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset position = renderBox.localToGlobal(localPosition, ancestor: overlay);

  showMenu(
    context: context,
    position: RelativeRect.fromRect(Rect.fromLTWH(position.dx, position.dy, 0, 0), Offset.zero & overlay.size),
    items: [
      PopupMenuItem(
        onTap: () => showDialog(
          context: context,
          builder: (context) => EditLabelDialog(label: label),
        ),
        child: const ListTile(leading: Icon(Icons.edit), title: Text('Edit'), dense: true),
      ),
      PopupMenuItem(
        onTap: () => showDialog(
          context: context,
          builder: (context) => DeleteDialog(
            title: 'Delete Label',
            message: 'Are you sure you want to delete "${label.name}"?',
            onConfirm: () => provider.deleteLabel(label.id),
          ),
        ),
        child: const ListTile(
          leading: Icon(Icons.delete, color: AppColors.error),
          title: Text('Delete', style: TextStyle(color: AppColors.error)),
          dense: true,
        ),
      ),
    ],
  );
}
