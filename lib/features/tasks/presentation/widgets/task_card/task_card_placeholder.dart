import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskCardPlaceholder extends ConsumerWidget {
  final Task task;
  final double opacity;

  const TaskCardPlaceholder({
    super.key,
    required this.task,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final project = task.projectId != null
        ? ref.watch(projectProvider).getById(task.projectId!)
        : null;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
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
    );
  }
}
