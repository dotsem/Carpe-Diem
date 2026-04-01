import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/data/models/label.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/ui/widgets/chip/chip.dart';
import 'package:carpe_diem/ui/widgets/chip/label_chip.dart';
import 'package:carpe_diem/ui/widgets/priority_indicator.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/project.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Project? project;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isOverdue;
  final bool selectionMode;
  final bool? isChecked;
  final bool useTimer;
  final bool showScheduleDate;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? leading;
  final void Function(Offset localPosition, RenderBox renderBox)? onContextMenu;

  const TaskCard({
    super.key,
    required this.task,
    this.project,
    required this.onToggle,
    required this.onTap,
    this.trailing,
    this.isOverdue = false,
    this.selectionMode = false,
    this.isChecked,
    this.useTimer = true,
    this.showScheduleDate = false,
    this.autofocus = false,
    this.focusNode,
    this.leading,
    this.onContextMenu,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: AppConstants.taskCompletionDelaySeconds),
    );
    _checkPending();
  }

  void _checkPending() {
    final provider = context.read<TaskProvider>();
    if (provider.isTaskPending(widget.task.id)) {
      final progress = provider.getPendingProgress(widget.task.id);
      if (progress < 1.0) {
        _controller.value = progress;
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle(bool? value) {
    if (widget.isChecked != null || widget.selectionMode) {
      widget.onToggle(value);
      return;
    }

    final provider = context.read<TaskProvider>();

    if (widget.task.status.isDone) {
      widget.onToggle(value);
    } else if (widget.task.status.isInProgress) {
      final isNowPending = !provider.isTaskPending(widget.task.id);
      provider.toggleComplete(widget.task, useTimer: widget.useTimer);

      if (isNowPending && widget.useTimer) {
        _controller.value = 0;
        _controller.forward();
      } else {
        _controller.reset();
      }
    } else {
      // Todo -> immediately move to in progress
      widget.onToggle(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isPending = provider.isTaskPending(widget.task.id);
    final bool showDone = widget.isChecked == null && (widget.task.isCompleted || isPending);

    // Sync animation if needed (e.g. after page swap)
    if (isPending && !_controller.isAnimating && _controller.value < 1.0) {
      final progress = provider.getPendingProgress(widget.task.id);
      _controller.value = progress;
      _controller.forward();
    } else if (!isPending && (_controller.isAnimating || _controller.value > 0)) {
      _controller.reset();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = widget.task.deadline != null ? widget.task.deadline!.isBefore(today) : widget.isOverdue;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: isPending
              ? _ProgressPainter(progress: _controller.value, color: AppColors.accent, width: 3.0, borderRadius: 12.0)
              : null,
          child: child,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (focused && mounted) {
              Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200), alignment: 0.5);
            }
            setState(() => _isFocused = focused);
          },
          onSecondaryTapDown: widget.onContextMenu != null
              ? (details) => widget.onContextMenu!(details.localPosition, context.findRenderObject() as RenderBox)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: _isFocused ? Border.all(color: AppColors.accent, width: 2) : null,
              gradient: widget.project?.color != null
                  ? LinearGradient(
                      colors: [AppColors.surface, widget.project!.color],
                      begin: Alignment.center,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  Positioned(left: 0, top: 0, bottom: 0, child: PriorityIndicator(priority: widget.task.priority)),
                  Padding(
                    padding: const EdgeInsets.only(left: 14), // indicator width (6) + gap (8)
                    child: Row(
                      children: [
                        widget.leading ?? _statusIndicator(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  decoration: (!widget.selectionMode && showDone) ? TextDecoration.lineThrough : null,
                                  color: (showDone && !widget.selectionMode) ? AppColors.textSecondary : AppColors.text,
                                ),
                              ),
                              if (widget.task.description != null && widget.task.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    widget.task.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ),
                              if (widget.project != null ||
                                  isOverdue ||
                                  widget.task.status.isInProgress ||
                                  widget.task.deadline != null ||
                                  widget.task.labelIds.isNotEmpty ||
                                  (widget.showScheduleDate && widget.task.scheduledDate != null)) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    if (isOverdue && !widget.task.isCompleted && !isPending) OverdueChip(),
                                    if (widget.task.status.isInProgress && !isPending) StatusChip(),
                                    if (widget.task.deadline != null) DeadlineChip(deadline: widget.task.deadline!),
                                    if (widget.showScheduleDate &&
                                        widget.task.scheduledDate != null &&
                                        ((widget.task.scheduledDate!.isBefore(today) && !widget.task.isCompleted) ||
                                            widget.task.scheduledDate!.isAtSameMomentAs(today) ||
                                            widget.task.scheduledDate!.isAfter(today)))
                                      ScheduledChip(scheduledDate: widget.task.scheduledDate!),
                                    if (widget.project != null) ProjectChip(project: widget.project),
                                    ..._getLabels(context),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.trailing != null) widget.trailing!,
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

  Widget _statusIndicator() {
    final bool effectiveIsChecked = widget.isChecked ?? widget.task.isCompleted;

    if (widget.selectionMode) {
      return Checkbox(
        value: widget.isChecked ?? false,
        onChanged: (value) => widget.onToggle(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );
    }

    final provider = context.read<TaskProvider>();
    final isPending = provider.isTaskPending(widget.task.id);

    if (widget.task.status.isInProgress) {
      return GestureDetector(
        onTap: () => _handleToggle(null),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPending ? AppColors.accent.withValues(alpha: 0.5) : AppColors.accent.withValues(alpha: 0.3),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: isPending ? const Icon(Icons.close, size: 14, color: AppColors.accent) : null,
        ),
      );
    }

    if (widget.task.status.isTodo) {
      return GestureDetector(
        onTap: () => _handleToggle(null),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.success),
        ),
      );
    }

    return Checkbox(
      value: effectiveIsChecked,
      onChanged: (value) => _handleToggle(value),
      fillColor: isPending ? WidgetStateProperty.all(AppColors.accent.withValues(alpha: 0.5)) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  List<Widget> _getLabels(BuildContext context) {
    final labelProvider = context.watch<LabelProvider>();
    final Set<String> allLabelIds = {...widget.task.labelIds};
    if (widget.project != null) {
      allLabelIds.addAll(widget.project!.labelIds);
    }

    final labels = allLabelIds.map((id) => labelProvider.getById(id)).whereType<Label>().toList();

    return labels.map((label) => LabelChip(label: label, verticalPadding: 1)).toList();
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;
  final double borderRadius;

  _ProgressPainter({required this.progress, required this.color, required this.width, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0.0, metrics.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
