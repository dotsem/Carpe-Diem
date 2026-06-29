import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/tag_chip.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskChipsBar extends ConsumerWidget {
  final Task task;
  final Project? project;
  final bool isOverdue;
  final bool showScheduleDate;

  const TaskChipsBar({
    super.key,
    required this.task,
    this.project,
    required this.isOverdue,
    required this.showScheduleDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Watch providers
    ref.watch(labelProvider);
    ref.watch(tagProvider);

    final labelNotifier = ref.read(labelProvider.notifier);
    final tagNotifier = ref.read(tagProvider.notifier);

    // Labels
    final Set<String> allLabelIds = {...task.labelIds};
    if (project != null) {
      allLabelIds.addAll(project!.labelIds);
    }
    final labels = allLabelIds.map((id) => labelNotifier.getById(id)).whereType<Label>().toList();

    // Tags
    final tags = task.tagIds.map((id) => tagNotifier.getById(id)).whereType<Tag>().toList();

    final hasChips = project != null ||
        isOverdue ||
        task.status.isInProgress ||
        task.deadline != null ||
        labels.isNotEmpty ||
        tags.isNotEmpty ||
        (showScheduleDate && task.scheduledDate != null);

    if (!hasChips) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (isOverdue && !task.isCompleted) const OverdueChip(),
        if (task.status.isInProgress) const StatusChip(),
        if (task.deadline != null) DeadlineChip(deadline: task.deadline!),
        if (showScheduleDate &&
            task.scheduledDate != null &&
            ((task.scheduledDate!.isBefore(today) && !task.isCompleted) ||
                task.scheduledDate!.isAtSameMomentAs(today) ||
                task.scheduledDate!.isAfter(today)))
          ScheduledChip(scheduledDate: task.scheduledDate!),
        if (project != null) ProjectChip(project: project),
        ...labels.map((label) => LabelChip(label: label, verticalPadding: 1)),
        ...tags.map((tag) => TagChip(tag: tag, verticalPadding: 1)),
      ],
    );
  }
}
