import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:flutter/material.dart';

class TaskListSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final int amount;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TaskListSectionHeader({
    super.key,
    required this.title,
    this.color,
    required this.amount,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SmallChip(
          color: color?.withValues(alpha: 0.15) ?? Colors.transparent,
          borderRadius: 10,
          child: Text(
            '$amount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }
    return content;
  }
}

class TaskListEmptyPlaceholder extends StatelessWidget {
  final Widget? customPlaceholder;

  const TaskListEmptyPlaceholder({super.key, this.customPlaceholder});

  @override
  Widget build(BuildContext context) {
    if (customPlaceholder != null) return customPlaceholder!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskListKeyboardShortcuts extends StatelessWidget {
  final bool enablePlanShortcut;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onPlanToday;
  final VoidCallback onPlanTomorrow;
  final Widget child;

  const TaskListKeyboardShortcuts({
    super.key,
    required this.enablePlanShortcut,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onPlanToday,
    required this.onPlanTomorrow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: Map.fromEntries([
        if (enablePlanShortcut) ...[
          const MapEntry(
            SingleActivator(TodayKeys.keyboardKey, control: true),
            PlanTaskIntent(),
          ),
          const MapEntry(
            SingleActivator(TodayKeys.keyboardKey, control: true, shift: true),
            PlanTaskTomorrowIntent(),
          ),
        ],
      ]),
      child: Actions(
        actions: {
          MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
          MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
          PlanTaskIntent: NonTypingAction<PlanTaskIntent>((_) => onPlanToday()),
          PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>(
            (_) => onPlanTomorrow(),
          ),
        },
        child: child,
      ),
    );
  }
}
