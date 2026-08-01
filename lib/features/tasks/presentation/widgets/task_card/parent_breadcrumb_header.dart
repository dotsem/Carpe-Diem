import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentBreadcrumbHeader extends ConsumerWidget {
  final String parentId;

  const ParentBreadcrumbHeader({super.key, required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final allStateTasks = [
      ...taskState.tasks,
      ...taskState.overdueTasks,
      ...taskState.unscheduledTasks,
    ];
    final parentTask = allStateTasks.where((t) => t.id == parentId).firstOrNull;
    if (parentTask == null) return const SizedBox.shrink();

    final cleanTitle = TagParser.hideHashtagSymbols(parentTask.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              cleanTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
