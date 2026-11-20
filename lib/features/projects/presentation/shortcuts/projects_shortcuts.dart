import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class UnfocusSearchIntent extends Intent {
  const UnfocusSearchIntent();
}

class ProjectsShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onFocusSearch;
  final VoidCallback onUnfocusSearch;
  final VoidCallback onShowFilter;
  final VoidCallback onNewTask;

  const ProjectsShortcuts({
    required this.child,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onFocusSearch,
    required this.onUnfocusSearch,
    required this.onShowFilter,
    required this.onNewTask,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: projectShortcutEntries,
      child: Shortcuts(
        shortcuts: const {
          CharacterActivator(SearchKeys.char): FocusSearchIntent(),
          SingleActivator(AppKeyBindings.escape): UnfocusSearchIntent(),
          CharacterActivator(DownKeys.char): MoveNextIntent(),
          CharacterActivator(UpKeys.char): MovePrevIntent(),
          CharacterActivator(LeftKeys.char): MoveLeftIntent(),
          CharacterActivator(RightKeys.char): MoveRightIntent(),
          SingleActivator(AppKeyBindings.arrowDown): MoveNextIntent(),
          SingleActivator(AppKeyBindings.arrowUp): MovePrevIntent(),
          SingleActivator(AppKeyBindings.arrowLeft): MoveLeftIntent(),
          SingleActivator(AppKeyBindings.arrowRight): MoveRightIntent(),
          CharacterActivator(FilterKeys.char): FilterIntent(),
          CharacterActivator(AddKeys.char): NewTaskIntent(),
          CharacterActivator(AddKeys.upper): NewTaskIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>(
              (_) => onMoveNext(),
            ),
            MovePrevIntent: NonTypingAction<MovePrevIntent>(
              (_) => onMovePrev(),
            ),
            MoveLeftIntent: NonTypingAction<MoveLeftIntent>(
              (_) => onMoveLeft(),
            ),
            MoveRightIntent: NonTypingAction<MoveRightIntent>(
              (_) => onMoveRight(),
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
          },
          child: child,
        ),
      ),
    );
  }
}
