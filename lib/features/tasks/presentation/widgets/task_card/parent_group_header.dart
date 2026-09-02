import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/tag_chip.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentGroupHeader extends ConsumerStatefulWidget {
  final ParentContainerNode node;
  final Project? project;
  final FocusNode? focusNode;
  final bool? isChecked;
  final bool selectionMode;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback? onTap;
  final void Function(Offset localPosition, RenderBox renderBox)? onContextMenu;
  final Widget? trailing;

  const ParentGroupHeader({
    super.key,
    required this.node,
    this.project,
    this.focusNode,
    this.isChecked = false,
    this.selectionMode = false,
    this.onToggle,
    this.onTap,
    this.onContextMenu,
    this.trailing,
  });

  @override
  ConsumerState<ParentGroupHeader> createState() => _ParentGroupHeaderState();
}

class _ParentGroupHeaderState extends ConsumerState<ParentGroupHeader> {
  @override
  Widget build(BuildContext context) {
    final task = widget.node.task;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUrgent = widget.node.hasUrgentChild || task.isUrgent;

    final progressText =
        '${widget.node.completedSubtasks}/${widget.node.totalSubtasks}';
    final cleanTitle = TagParser.hideHashtagSymbols(task.title);

    ref.watch(labelProvider);
    ref.watch(tagProvider);

    final labelNotifier = ref.read(labelProvider.notifier);
    final tagNotifier = ref.read(tagProvider.notifier);

    final Set<String> allLabelIds = {...task.labelIds};
    if (widget.project != null) {
      allLabelIds.addAll(widget.project!.labelIds);
    }
    final labels = allLabelIds
        .map((id) => labelNotifier.getById(id))
        .whereType<Label>()
        .toList();

    final tags = task.tagIds
        .map((id) => tagNotifier.getById(id))
        .whereType<Tag>()
        .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        borderRadius: BorderRadius.circular(10),
        onTap:
            widget.onTap ??
            () {
              ref
                  .read(collapsedSubtasksProvider.notifier)
                  .toggleCollapse(task.id);
            },
        onSecondaryTapDown: widget.onContextMenu != null
            ? (details) => widget.onContextMenu!(
                details.localPosition,
                context.findRenderObject() as RenderBox,
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUrgent
                  ? AppColors.error.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isUrgent ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Checkbox(
                    value: widget.isChecked,
                    tristate: true,
                    onChanged: widget.onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                icon: Icon(
                  widget.node.isCollapsed
                      ? Icons.keyboard_arrow_right_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  ref
                      .read(collapsedSubtasksProvider.notifier)
                      .toggleCollapse(task.id);
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        cleanTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.project != null ||
                        labels.isNotEmpty ||
                        tags.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      if (widget.project != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ProjectChip(project: widget.project),
                        ),
                      ...labels.map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: LabelChip(label: l, verticalPadding: 1),
                        ),
                      ),
                      ...tags.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TagChip(tag: t, verticalPadding: 1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUrgent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 12,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Urgent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.node.plannedSubtasks > 0) ...[
                const SizedBox(width: 6),
                SmallChip(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: 6,
                  child: Text(
                    '${widget.node.plannedSubtasks} planned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              SmallChip(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: 6,
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 4),
                widget.trailing!,
              ] else
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit parent task',
                  onPressed: () {
                    context.openRightSidebar(EditTaskPanel(task.id), ref);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
