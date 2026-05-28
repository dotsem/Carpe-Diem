import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class UnfocusSearchIntent extends Intent {
  const UnfocusSearchIntent();
}

class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class BacklogShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onShowFilter;
  final VoidCallback onFocusSearch;
  final VoidCallback onUnfocusSearch;
  final VoidCallback onNewTask;
  final VoidCallback onPlanTask;
  final VoidCallback onPlanTaskTomorrow;

  const BacklogShortcuts({
    super.key,
    required this.child,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onShowFilter,
    required this.onFocusSearch,
    required this.onUnfocusSearch,
    required this.onNewTask,
    required this.onPlanTask,
    required this.onPlanTaskTomorrow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: backlogShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(SearchKeys.char): const FocusSearchIntent(),
          const SingleActivator(AppKeyBindings.escape): const UnfocusSearchIntent(),
          const CharacterActivator(AddKeys.char): const NewTaskIntent(),
          const CharacterActivator(AddKeys.upper): const NewTaskIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
          const SingleActivator(TodayKeys.keyboardKey, control: true): const PlanTaskIntent(),
          const SingleActivator(TodayKeys.keyboardKey, control: true, shift: true): const PlanTaskTomorrowIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
            FocusSearchIntent: NonTypingAction<FocusSearchIntent>((_) => onFocusSearch()),
            UnfocusSearchIntent: CallbackAction<UnfocusSearchIntent>(
              onInvoke: (intent) {
                onUnfocusSearch();
                return null;
              },
            ),
            NewTaskIntent: NonTypingAction<NewTaskIntent>((_) => onNewTask()),
            PlanTaskIntent: NonTypingAction<PlanTaskIntent>((_) => onPlanTask()),
            PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>((_) => onPlanTaskTomorrow()),
          },
          child: child,
        ),
      ),
    );
  }
}
