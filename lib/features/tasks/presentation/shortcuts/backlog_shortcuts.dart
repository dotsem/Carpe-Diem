import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final VoidCallback onPrevTab;
  final VoidCallback onNextTab;
  final VoidCallback onShowFilter;
  final VoidCallback onFocusSearch;
  final VoidCallback onUnfocusSearch;
  final VoidCallback onNewTask;
  final VoidCallback onPlanTask;
  final VoidCallback onPlanTaskTomorrow;

  const BacklogShortcuts({
    required this.child,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onPrevTab,
    required this.onNextTab,
    required this.onShowFilter,
    required this.onFocusSearch,
    required this.onUnfocusSearch,
    required this.onNewTask,
    required this.onPlanTask,
    required this.onPlanTaskTomorrow,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: backlogShortcutEntries,
      child: Shortcuts(
        shortcuts: const {
          CharacterActivator(SearchKeys.char): FocusSearchIntent(),
          SingleActivator(AppKeyBindings.escape): UnfocusSearchIntent(),
          CharacterActivator(AddKeys.char): NewTaskIntent(),
          CharacterActivator(AddKeys.upper): NewTaskIntent(),
          CharacterActivator(DownKeys.char): MoveNextIntent(),
          CharacterActivator(UpKeys.char): MovePrevIntent(),
          CharacterActivator(LeftKeys.char): MoveLeftIntent(),
          CharacterActivator(LeftKeys.upper): MoveLeftIntent(),
          SingleActivator(AppKeyBindings.arrowLeft): MoveLeftIntent(),
          CharacterActivator(RightKeys.char): MoveRightIntent(),
          CharacterActivator(RightKeys.upper): MoveRightIntent(),
          SingleActivator(AppKeyBindings.arrowRight): MoveRightIntent(),
          CharacterActivator(FilterKeys.char): FilterIntent(),
          SingleActivator(TodayKeys.keyboardKey, control: true):
              PlanTaskIntent(),
          SingleActivator(TodayKeys.keyboardKey, control: true, shift: true):
              PlanTaskTomorrowIntent(),
          SingleActivator(AppKeyBindings.arrowDown): MoveNextIntent(),
          SingleActivator(AppKeyBindings.arrowUp): MovePrevIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>(
              (_) => onMoveNext(),
            ),
            MovePrevIntent: NonTypingAction<MovePrevIntent>(
              (_) => onMovePrev(),
            ),
            MoveLeftIntent: NonTypingAction<MoveLeftIntent>((_) => onPrevTab()),
            MoveRightIntent: NonTypingAction<MoveRightIntent>(
              (_) => onNextTab(),
            ),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
            FocusSearchIntent: NonTypingAction<FocusSearchIntent>(
              (_) => onFocusSearch(),
            ),
            UnfocusSearchIntent: CallbackAction<UnfocusSearchIntent>(
              onInvoke: (intent) {
                onUnfocusSearch();
                return null;
              },
            ),
            NewTaskIntent: NonTypingAction<NewTaskIntent>((_) => onNewTask()),
            PlanTaskIntent: NonTypingAction<PlanTaskIntent>(
              (_) => onPlanTask(),
            ),
            PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>(
              (_) => onPlanTaskTomorrow(),
            ),
          },
          child: child,
        ),
      ),
    );
  }
}
