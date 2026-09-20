import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_breadcrumb_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_chips_bar.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class BaseTaskCard extends StatefulWidget {
  final Task task;
  final Project? project;
  final Widget? leading;
  final Widget? trailing;
  final Widget Function(BuildContext context, bool isHovered)? trailingBuilder;

  final bool isOverdue;
  final bool selectionMode;
  final bool showDone;
  final bool showScheduleDate;
  final bool showStrikeThroughOnCompleted;

  final bool isFocused;
  final bool isHighlighted;

  final bool compactMode;
  final bool showDescriptionOnCard;
  final bool showHashtagInTitle;
  final double taskGradientWidth;

  final VoidCallback? onTap;
  final void Function(Offset, RenderBox)? onContextMenu;
  final void Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Hides the project info, inherited labels, project color and parent breadcrumb.
  final bool hideProjectInfo;
  final bool? hideProjectGradient;

  const BaseTaskCard({
    super.key,
    required this.task,
    this.project,
    this.leading,
    this.trailing,
    this.trailingBuilder,
    this.isOverdue = false,
    this.selectionMode = false,
    this.showDone = false,
    this.showScheduleDate = false,
    this.showStrikeThroughOnCompleted = true,
    this.isFocused = false,
    this.isHighlighted = false,
    this.compactMode = false,
    this.showDescriptionOnCard = true,
    this.showHashtagInTitle = true,
    this.taskGradientWidth = 0.5,
    this.onTap,
    this.onContextMenu,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.hideProjectInfo = false,
    this.hideProjectGradient,
  });

  @override
  State<BaseTaskCard> createState() => _BaseTaskCardState();
}

class _BaseTaskCardState extends State<BaseTaskCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasHighlight = widget.isFocused || widget.isHighlighted;
    final isHoveredOrFocused =
        _isHovered || widget.isFocused || widget.isHighlighted;

    Widget? trailingWidget = widget.trailing;
    if (widget.trailingBuilder != null) {
      trailingWidget = widget.trailingBuilder!(context, isHoveredOrFocused);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: widget.compactMode ? 2 : 4),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: hasHighlight
                ? Border.all(color: AppColors.accent, width: 2)
                : null,
            gradient:
                (widget.project?.color != null &&
                    !(widget.hideProjectGradient ?? widget.hideProjectInfo))
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                      widget.project!.color
                          .themeDependentColor(context)
                          .withValues(alpha: 0),
                      widget.project!.color
                          .themeDependentColor(context)
                          .withValues(alpha: 0.4),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [
                      0.0,
                      (1.0 - widget.taskGradientWidth).clamp(0.0, 1.0),
                      (1.0 - widget.taskGradientWidth).clamp(0.0, 1.0),
                      1.0,
                    ],
                  )
                : null,
          ),
          child: InkWell(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            mouseCursor: SystemMouseCursors.click,
            onHover: (hovered) => setState(() => _isHovered = hovered),
            onFocusChange: widget.onFocusChange,
            onSecondaryTapDown: widget.onContextMenu != null
                ? (details) => widget.onContextMenu!(
                    details.localPosition,
                    context.findRenderObject() as RenderBox,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: widget.compactMode ? 4 : 8,
              ),
              child: Stack(
                children: [
                  if (widget.task.isUrgent)
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
                    padding: EdgeInsets.only(
                      left: widget.task.isUrgent ? 14 : 0,
                    ),
                    child: Row(
                      children: [
                        ?widget.leading,
                        if (widget.leading != null)
                          SizedBox(width: widget.compactMode ? 6 : 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.task.parentId != null &&
                                  !widget.hideProjectInfo)
                                ParentBreadcrumbHeader(
                                  parentId: widget.task.parentId!,
                                ),
                              Text(
                                widget.showHashtagInTitle
                                    ? widget.task.title
                                    : TagParser.hideHashtagSymbols(
                                        widget.task.title,
                                      ),
                                style: TextStyle(
                                  fontSize: widget.compactMode ? 14 : 15,
                                  fontWeight: FontWeight.w500,
                                  decoration:
                                      (!widget.selectionMode &&
                                          widget.showDone &&
                                          widget.showStrikeThroughOnCompleted)
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color:
                                      (widget.showDone && !widget.selectionMode)
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (widget.showDescriptionOnCard &&
                                  widget.task.description != null &&
                                  widget.task.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    widget.task.description!.contains('\n')
                                        ? '${widget.task.description!.split('\n').first.trim()}...'
                                        : widget.task.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: widget.compactMode ? 12 : 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              TaskChipsBar(
                                task: widget.task,
                                project: widget.hideProjectInfo
                                    ? null
                                    : widget.project,
                                isOverdue: widget.isOverdue && !widget.showDone,
                                showScheduleDate: widget.showScheduleDate,
                              ),
                            ],
                          ),
                        ),
                        ?trailingWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
