import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrevDayIntent extends Intent {
  const PrevDayIntent();
}

class NextDayIntent extends Intent {
  const NextDayIntent();
}

class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class ToggleLayoutIntent extends Intent {
  const ToggleLayoutIntent();
}

class HomeShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onNewTask;
  final VoidCallback onToggleLayout;
  final VoidCallback onShowFilter;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onNavigateToToday;

  const HomeShortcuts({
    required this.child,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onNewTask,
    required this.onToggleLayout,
    required this.onShowFilter,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onNavigateToToday,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: homeShortcutEntries,
      child: Shortcuts(
        shortcuts: const {
          CharacterActivator(LeftKeys.char): PrevDayIntent(),
          CharacterActivator(RightKeys.char): NextDayIntent(),
          CharacterActivator(AddKeys.char): NewTaskIntent(),
          CharacterActivator(ToggleLayoutKeys.char): ToggleLayoutIntent(),
          CharacterActivator(FilterKeys.char): FilterIntent(),
          CharacterActivator(LeftKeys.upper): PrevDayIntent(),
          CharacterActivator(RightKeys.upper): NextDayIntent(),
          CharacterActivator(AddKeys.upper): NewTaskIntent(),
          CharacterActivator(ToggleLayoutKeys.upper): ToggleLayoutIntent(),
          CharacterActivator(DownKeys.char): MoveNextIntent(),
          CharacterActivator(UpKeys.char): MovePrevIntent(),
          SingleActivator(AppKeyBindings.arrowLeft): PrevDayIntent(),
          SingleActivator(AppKeyBindings.arrowRight): NextDayIntent(),
          SingleActivator(AppKeyBindings.arrowDown): MoveNextIntent(),
          SingleActivator(AppKeyBindings.arrowUp): MovePrevIntent(),
        },
        child: Actions(
          actions: {
            PrevDayIntent: NonTypingAction<PrevDayIntent>((_) => onPrevDay()),
            NextDayIntent: NonTypingAction<NextDayIntent>((_) => onNextDay()),
            NewTaskIntent: NonTypingAction<NewTaskIntent>((_) => onNewTask()),
            ToggleLayoutIntent: NonTypingAction<ToggleLayoutIntent>(
              (_) => onToggleLayout(),
            ),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
            MoveNextIntent: NonTypingAction<MoveNextIntent>(
              (_) => onMoveNext(),
            ),
            MovePrevIntent: NonTypingAction<MovePrevIntent>(
              (_) => onMovePrev(),
            ),
            NavigateToTodayIntent: NonTypingAction<NavigateToTodayIntent>(
              (_) => onNavigateToToday(),
            ),
          },
          child: child,
        ),
      ),
    );
  }
}
