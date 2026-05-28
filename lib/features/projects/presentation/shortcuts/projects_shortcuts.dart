import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';

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

  const ProjectsShortcuts({
    super.key,
    required this.child,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onFocusSearch,
    required this.onUnfocusSearch,
    required this.onShowFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: projectShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(SearchKeys.char): const FocusSearchIntent(),
          const SingleActivator(AppKeyBindings.escape): const UnfocusSearchIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const CharacterActivator(LeftKeys.char): const MoveLeftIntent(),
          const CharacterActivator(RightKeys.char): const MoveRightIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
          const SingleActivator(AppKeyBindings.arrowLeft): const MoveLeftIntent(),
          const SingleActivator(AppKeyBindings.arrowRight): const MoveRightIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
            MoveLeftIntent: NonTypingAction<MoveLeftIntent>((_) => onMoveLeft()),
            MoveRightIntent: NonTypingAction<MoveRightIntent>((_) => onMoveRight()),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
            FocusSearchIntent: NonTypingAction<FocusSearchIntent>((_) => onFocusSearch()),
            UnfocusSearchIntent: CallbackAction<UnfocusSearchIntent>(
              onInvoke: (intent) {
                onUnfocusSearch();
                return null;
              },
            ),
          },
          child: child,
        ),
      ),
    );
  }
}
