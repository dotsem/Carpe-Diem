import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class TaskDragProxy extends StatelessWidget {
  final Task task;
  final int selectedCount;
  final bool showHashtagInTitle;

  const TaskDragProxy({
    super.key,
    required this.task,
    required this.selectedCount,
    required this.showHashtagInTitle,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = showHashtagInTitle ? task.title : TagParser.hideHashtagSymbols(task.title);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (selectedCount > 2)
            Transform.translate(
              offset: const Offset(8, 8),
              child: TaskDragProxyCard(titleText: titleText, opacity: 0.5),
            ),
          if (selectedCount > 1)
            Transform.translate(
              offset: const Offset(4, 4),
              child: TaskDragProxyCard(titleText: titleText, opacity: 0.8),
            ),
          TaskDragProxyCard(titleText: titleText, opacity: 1.0),
          if (selectedCount > 1)
            Positioned(
              top: -8,
              right: -8,
              child: Badge(
                label: Text('$selectedCount'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                largeSize: 24,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class TaskDragProxyCard extends StatelessWidget {
  final String titleText;
  final double opacity;

  const TaskDragProxyCard({
    super.key,
    required this.titleText,
    required this.opacity,
  });

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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          titleText,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
