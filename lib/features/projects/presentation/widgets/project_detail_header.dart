import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_indicator.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';

class ProjectDetailHeader extends ConsumerWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onImportMd;

  const ProjectDetailHeader({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
    required this.onImportMd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(labelProvider);
    final labels = project.labelIds.map((id) => labelState.getById(id)).whereType<Label>().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 16),
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: PriorityIndicator(priority: project.priority)),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: project.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: onEdit,
                        tooltip: 'Edit Project',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: onDelete,
                        tooltip: 'Delete Project',
                      ),
                      const SizedBox(width: 8),
                      BulkActionMenu(
                        options: [
                          BulkActionOption(
                            value: 'import',
                            icon: Icons.download,
                            label: 'Import from Markdown',
                            enabled: true,
                          ),
                        ],
                        onOptionSelected: (value) {
                          if (value == 'import') {
                            onImportMd();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (project.deadline != null) DeadlineChip(deadline: project.deadline!),
                    ...labels.map((label) => LabelChip(label: label, verticalPadding: 1)),
                  ],
                ),
                if (project.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    project.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
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
