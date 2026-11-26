import 'dart:async';

import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/delete_project_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Title row of the project detail screen with the project's edit, import,
/// archive, delete and add-task actions.
class ProjectDetailHeader extends ConsumerWidget {
  final Project project;

  const ProjectDetailHeader({required this.project, super.key});

  void _delete(BuildContext context, WidgetRef ref) => unawaited(
    showDeleteProjectDialog(
      context,
      ref,
      project,
      onDeleted: () {
        if (context.mounted) {
          GoRouter.of(context).go('/projects');
        }
      },
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(labelProvider);
    final labels = project.labelIds
        .map(labelState.getById)
        .whereType<Label>()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        children: [
          if (project.isUrgent)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: project.isUrgent ? 22 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: project.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => context.openRightSidebar(
                          EditProjectPanel(project.id),
                        ),
                        tooltip: 'Edit Project',
                      ),

                      const SizedBox(width: 8),
                      BulkActionMenu(
                        options: [
                          const BulkActionOption(
                            value: 'import',
                            icon: Icons.download,
                            label: 'Import from Markdown',
                            enabled: true,
                          ),
                          BulkActionOption(
                            value: 'archive',
                            icon: project.isActive
                                ? Icons.archive_outlined
                                : Icons.unarchive_outlined,
                            label: project.isActive
                                ? 'Archive Project'
                                : 'Restore Project',
                            enabled: true,
                          ),
                          const BulkActionOption(
                            value: 'delete',
                            icon: Icons.delete_outline,
                            label: 'Delete Project',
                            enabled: true,
                            isDestructive: true,
                          ),
                        ],
                        onOptionSelected: (value) {
                          switch (value) {
                            case 'import':
                              unawaited(
                                showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      ImportFromMDDialog(project: project),
                                ),
                              );
                            case 'archive':
                              ref
                                  .read(projectProvider.notifier)
                                  .toggleProjectActive(project);
                            case 'delete':
                              _delete(context, ref);
                          }
                        },
                      ),
                      if (project.isActive) ...[
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => context.openRightSidebar(
                            AddTaskPanel(initialProjectId: project.id),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Task'),
                        ),
                      ],
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (project.deadline != null)
                      DeadlineChip(
                        deadline: project.deadline!,
                        today: DateTime.now().normalize,
                      ),
                    ...labels.map(
                      (label) => LabelChip(label: label, verticalPadding: 1),
                    ),
                  ],
                ),
                if (project.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    project.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
