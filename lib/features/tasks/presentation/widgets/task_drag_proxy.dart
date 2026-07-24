import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';

class TaskDragProxy extends ConsumerWidget {
  final Task task;
  final int selectedCount;
  final double width;

  const TaskDragProxy({super.key, required this.task, required this.selectedCount, required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final project = task.projectId != null ? ref.watch(projectProvider).getById(task.projectId!) : null;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IgnorePointer(
              child: BaseTaskCard(
                task: task,
                project: project,
                compactMode: settings.compactMode,
                showDescriptionOnCard: settings.showDescriptionOnCard,
                showHashtagInTitle: settings.showHashtagInTitle,
                taskGradientWidth: settings.taskGradientWidth,
                isOverdue: task.isOverdue,
              ),
            ),
            if (selectedCount > 1)
              Transform.translate(
                offset: Offset(0, settings.compactMode ? -14 : -16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        thickness: 3,
                        indent: 8,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '+ ${selectedCount - 1} task${selectedCount - 1 != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        thickness: 3,
                        endIndent: 8,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TaskDragProxyCard extends StatelessWidget {
  final String titleText;
  final double opacity;

  const TaskDragProxyCard({super.key, required this.titleText, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          titleText,
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
