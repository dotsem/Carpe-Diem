import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDeleteProjectDialog(
  BuildContext context,
  WidgetRef ref,
  Project project, {
  VoidCallback? onDeleted,
}) async {
  return showDialog(
    context: context,
    builder: (ctx) => DeleteDialog(
      title: 'Delete Project',
      message:
          'Are you sure you want to delete "${project.name}"? This will not delete the tasks, but they will no longer be associated with this project.',
      onConfirm: () async {
        final notifier = ref.read(projectProvider.notifier);
        await notifier.deleteProject(project);
        onDeleted?.call();
      },
    ),
  );
}
