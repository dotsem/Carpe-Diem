import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';

import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_progress_border_painter.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_status_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';

class TaskCard extends ConsumerStatefulWidget {
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
  final bool showStrikeThroughOnCompleted;
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
    this.showStrikeThroughOnCompleted = true,
    this.isChecked,
    this.useTimer = true,
    this.showScheduleDate = false,
    this.autofocus = false,
    this.focusNode,
    this.leading,
    this.onContextMenu,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: settings.taskCompletionDelay),
    );
    _checkPending();
  }

  void _checkPending() {
    final timerNotifier = ref.read(taskTimerProvider.notifier);
    final settings = ref.read(settingsProvider);
    if (timerNotifier.isTaskPending(widget.task.id)) {
      final progress = timerNotifier.getPendingProgress(widget.task.id, settings.taskCompletionDelay);
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

    final taskNotifier = ref.read(taskProvider.notifier);
    final timerNotifier = ref.read(taskTimerProvider.notifier);

    if (widget.task.status.isDone) {
      widget.onToggle(value);
    } else if (widget.task.status.isInProgress) {
      final isNowPending = !timerNotifier.isTaskPending(widget.task.id);
      taskNotifier.toggleComplete(widget.task, useTimer: widget.useTimer);

      if (isNowPending && widget.useTimer) {
        _controller.value = 0;
        _controller.forward();
      } else {
        _controller.reset();
      }
    } else {
      widget.onToggle(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(taskTimerProvider);
    final isPending = timerState.pendingCompletions.containsKey(widget.task.id);
    final bool showDone = widget.isChecked == null && (widget.task.isCompleted || isPending);
    final settings = ref.watch(settingsProvider);

    if (isPending && !_controller.isAnimating && _controller.value < 1.0) {
      final progress = ref
          .read(taskTimerProvider.notifier)
          .getPendingProgress(widget.task.id, settings.taskCompletionDelay);
      _controller.value = progress;
      _controller.forward();
    } else if (!isPending && (_controller.isAnimating || _controller.value > 0)) {
      _controller.reset();
    }

    final isOverdue = widget.task.isOverdue;

    final isCompact = settings.compactMode;
    final showDescription = settings.showDescriptionOnCard;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: isPending
              ? TaskProgressBorderPainter(
                  progress: _controller.value,
                  color: AppColors.accent,
                  width: 3.0,
                  borderRadius: 12.0,
                )
              : null,
          child: child,
        );
      },
      child: BaseTaskCard(
        task: widget.task,
        project: widget.project,
        leading: widget.leading ??
            TaskStatusIndicator(
              task: widget.task,
              isChecked: widget.isChecked,
              selectionMode: widget.selectionMode,
              onToggle: widget.onToggle,
              onToggleAction: () => _handleToggle(null),
            ),
        trailing: widget.trailing,
        isOverdue: isOverdue,
        selectionMode: widget.selectionMode,
        showDone: showDone,
        showScheduleDate: widget.showScheduleDate,
        showStrikeThroughOnCompleted: widget.showStrikeThroughOnCompleted,
        isFocused: _isFocused,
        compactMode: isCompact,
        showDescriptionOnCard: showDescription,
        showHashtagInTitle: settings.showHashtagInTitle,
        taskGradientWidth: settings.taskGradientWidth,
        onTap: widget.onTap,
        onContextMenu: widget.onContextMenu,
        onFocusChange: (focused) {
          if (focused && mounted) {
            Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200), alignment: 0.5);
          }
          setState(() => _isFocused = focused);
        },
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
      ),
    );
  }
}
