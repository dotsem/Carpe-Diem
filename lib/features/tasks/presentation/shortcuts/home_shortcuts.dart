import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';

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
    super.key,
    required this.child,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onNewTask,
    required this.onToggleLayout,
    required this.onShowFilter,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onNavigateToToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: homeShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(LeftKeys.char): const PrevDayIntent(),
          const CharacterActivator(RightKeys.char): const NextDayIntent(),
          const CharacterActivator(AddKeys.char): const NewTaskIntent(),
          const CharacterActivator(ToggleLayoutKeys.char): const ToggleLayoutIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
          const CharacterActivator(LeftKeys.upper): const PrevDayIntent(),
          const CharacterActivator(RightKeys.upper): const NextDayIntent(),
          const CharacterActivator(AddKeys.upper): const NewTaskIntent(),
          const CharacterActivator(ToggleLayoutKeys.upper): const ToggleLayoutIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const SingleActivator(AppKeyBindings.arrowLeft): const PrevDayIntent(),
          const SingleActivator(AppKeyBindings.arrowRight): const NextDayIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
        },
        child: Actions(
          actions: {
            PrevDayIntent: NonTypingAction<PrevDayIntent>((_) => onPrevDay()),
            NextDayIntent: NonTypingAction<NextDayIntent>((_) => onNextDay()),
            NewTaskIntent: NonTypingAction<NewTaskIntent>((_) => onNewTask()),
            ToggleLayoutIntent: NonTypingAction<ToggleLayoutIntent>((_) => onToggleLayout()),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
            NavigateToTodayIntent: NonTypingAction<NavigateToTodayIntent>((_) => onNavigateToToday()),
          },
          child: child,
        ),
      ),
    );
  }
}
