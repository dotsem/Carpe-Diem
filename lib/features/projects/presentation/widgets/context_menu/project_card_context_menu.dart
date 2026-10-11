import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/widgets/context_menu_item_tile.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/delete_project_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showProjectCardContextMenu(
  BuildContext context,
  Offset globalPosition,
  WidgetRef ref,
  Project project,
) {
  final projectNotifier = ref.read(projectProvider.notifier);
  final isActive = project.isActive;
  final RenderBox navigatorBox =
      Navigator.of(context).context.findRenderObject() as RenderBox;
  final Offset navigatorOffset = navigatorBox.localToGlobal(Offset.zero);

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      navigatorOffset & navigatorBox.size,
    ),
    items: [
      PopupMenuItem(
        child: const ContextMenuItemTile(
          leading: Icon(Icons.edit),
          title: 'Edit',
        ),
        onTap: () =>
            context.openRightSidebar(EditProjectPanel(project.id), ref),
      ),
      PopupMenuItem(
        child: ContextMenuItemTile(
          leading: Icon(
            isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
          ),
          title: isActive ? 'Archive Project' : 'Restore Project',
        ),
        onTap: () => projectNotifier.toggleProjectActive(project),
      ),

      if (!isActive)
        PopupMenuItem(
          child: const ContextMenuItemTile(
            leading: Icon(Icons.delete),
            title: 'Delete',
            color: AppColors.error,
          ),
          onTap: () => showDeleteProjectDialog(context, ref, project),
        ),
    ],
  );
}
