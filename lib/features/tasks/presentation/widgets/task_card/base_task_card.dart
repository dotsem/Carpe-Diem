import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_chips_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_indicator.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class BaseTaskCard extends StatelessWidget {
  final Task task;
  final Project? project;
  final Widget? leading;
  final Widget? trailing;
  
  final bool isOverdue;
  final bool selectionMode;
  final bool showDone;
  final bool showScheduleDate;
  final bool showStrikeThroughOnCompleted;
  
  final bool isFocused;
  
  final bool compactMode;
  final bool showDescriptionOnCard;
  final bool showHashtagInTitle;
  final double taskGradientWidth;
  
  final VoidCallback? onTap;
  final void Function(Offset, RenderBox)? onContextMenu;
  final void Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;

  const BaseTaskCard({
    super.key,
    required this.task,
    this.project,
    this.leading,
    this.trailing,
    this.isOverdue = false,
    this.selectionMode = false,
    this.showDone = false,
    this.showScheduleDate = false,
    this.showStrikeThroughOnCompleted = true,
    this.isFocused = false,
    this.compactMode = false,
    this.showDescriptionOnCard = true,
    this.showHashtagInTitle = true,
    this.taskGradientWidth = 0.5,
    this.onTap,
    this.onContextMenu,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: compactMode ? 2 : 4),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isFocused ? Border.all(color: AppColors.accent, width: 2) : null,
          gradient: project?.color != null
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                    project!.color.themeDependentColor(context).withValues(alpha: 0),
                    project!.color.themeDependentColor(context).withValues(alpha: 0.4),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [
                    0.0,
                    (1.0 - taskGradientWidth).clamp(0.0, 1.0),
                    (1.0 - taskGradientWidth).clamp(0.0, 1.0),
                    1.0,
                  ],
                )
              : null,
        ),
        child: InkWell(
          focusNode: focusNode,
          autofocus: autofocus,
          onTap: onTap,
          onFocusChange: onFocusChange,
          onSecondaryTapDown: onContextMenu != null
              ? (details) => onContextMenu!(details.localPosition, context.findRenderObject() as RenderBox)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: compactMode ? 4 : 8),
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, child: PriorityIndicator(priority: task.priority)),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      ?leading,
                      if (leading != null) SizedBox(width: compactMode ? 6 : 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              showHashtagInTitle
                                  ? task.title
                                  : TagParser.hideHashtagSymbols(task.title),
                              style: TextStyle(
                                fontSize: compactMode ? 14 : 15,
                                fontWeight: FontWeight.w500,
                                decoration: (!selectionMode && showDone && showStrikeThroughOnCompleted)
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: (showDone && !selectionMode)
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (showDescriptionOnCard &&
                                task.description != null &&
                                task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  task.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compactMode ? 12 : 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            TaskChipsBar(
                              task: task,
                              project: project,
                              isOverdue: isOverdue && !showDone,
                              showScheduleDate: showScheduleDate,
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
