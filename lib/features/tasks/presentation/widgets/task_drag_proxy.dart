import 'package:carpe_diem/features/common/presentation/widgets/swinging_drag_proxy.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDragProxy extends ConsumerWidget {
  final Task task;
  final int selectedCount;
  final double width;

  const TaskDragProxy({
    super.key,
    required this.task,
    required this.selectedCount,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final project = task.projectId != null
        ? ref.watch(projectProvider).getById(task.projectId!)
        : null;

    final cardContent = Material(
      color: Colors.transparent,
      elevation: 0,
      child: Transform.scale(
        scale: 1.02,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.6),
                            thickness: 3,
                            indent: 8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '+ ${selectedCount - 1} task${selectedCount - 1 != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.6),
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
        ),
      ),
    );

    return SwingingDragProxy(width: width, child: cardContent);
  }
}
