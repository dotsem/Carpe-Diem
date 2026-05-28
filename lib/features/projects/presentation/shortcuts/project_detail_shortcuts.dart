import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';

class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class UnfocusSearchIntent extends Intent {
  const UnfocusSearchIntent();
}

class ProjectDetailShortcuts extends ConsumerWidget {
  final Widget child;
  final Project project;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onFocusSearch;
  final VoidCallback onUnfocusSearch;
  final VoidCallback onNewTask;
  final VoidCallback onShowFilter;

  const ProjectDetailShortcuts({
    super.key,
    required this.child,
    required this.project,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onFocusSearch,
    required this.onUnfocusSearch,
    required this.onNewTask,
    required this.onShowFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: projectDetailShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(SearchKeys.char): const FocusSearchIntent(),
          const SingleActivator(AppKeyBindings.escape): const UnfocusSearchIntent(),
          if (project.isActive) const CharacterActivator(AddKeys.char): const NewTaskIntent(),
          if (project.isActive) const CharacterActivator(AddKeys.upper): const NewTaskIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
            FocusSearchIntent: NonTypingAction<FocusSearchIntent>((_) => onFocusSearch()),
            UnfocusSearchIntent: CallbackAction<UnfocusSearchIntent>(
              onInvoke: (intent) {
                onUnfocusSearch();
                return null;
              },
            ),
            if (project.isActive)
              NewTaskIntent: NonTypingAction<NewTaskIntent>((_) => onNewTask()),
            FilterIntent: NonTypingAction<FilterIntent>((_) => onShowFilter()),
          },
          child: child,
        ),
      ),
    );
  }
}
