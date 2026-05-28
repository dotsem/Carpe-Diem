import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';

class BaseScreenShortcuts extends ConsumerWidget {
  final Widget child;
  final List<ShortcutEntry> helpEntries;
  
  // Standard Callback Hooks
  final VoidCallback? onMoveNext;
  final VoidCallback? onMovePrev;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback? onFocusSearch;
  final VoidCallback? onUnfocusSearch;
  final VoidCallback? onFilter;
  final VoidCallback? onNewItem;

  // Extension points for screen-specific custom mappings
  final Map<ShortcutActivator, Intent>? customShortcuts;
  final Map<Type, Action<Intent>>? customActions;

  const BaseScreenShortcuts({
    super.key,
    required this.child,
    required this.helpEntries,
    this.onMoveNext,
    this.onMovePrev,
    this.onMoveLeft,
    this.onMoveRight,
    this.onFocusSearch,
    this.onUnfocusSearch,
    this.onFilter,
    this.onNewItem,
    this.customShortcuts,
    this.customActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShortcutRegistrar(
      shortcuts: helpEntries,
      child: Shortcuts(
        shortcuts: {
          // Default Common Activators
          if (onFocusSearch != null)
            const CharacterActivator(SearchKeys.char): const FocusSearchIntent(),
          if (onUnfocusSearch != null)
            const SingleActivator(AppKeyBindings.escape): const UnfocusSearchIntent(),
          if (onNewItem != null) ...{
            const CharacterActivator(AddKeys.char): const NewItemIntent(),
            const CharacterActivator(AddKeys.upper): const NewItemIntent(),
          },
          if (onMoveNext != null) ...{
            const CharacterActivator(DownKeys.char): const MoveNextIntent(),
            const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          },
          if (onMovePrev != null) ...{
            const CharacterActivator(UpKeys.char): const MovePrevIntent(),
            const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
          },
          if (onMoveLeft != null) ...{
            const CharacterActivator(LeftKeys.char): const MoveLeftIntent(),
            const SingleActivator(AppKeyBindings.arrowLeft): const MoveLeftIntent(),
          },
          if (onMoveRight != null) ...{
            const CharacterActivator(RightKeys.char): const MoveRightIntent(),
            const SingleActivator(AppKeyBindings.arrowRight): const MoveRightIntent(),
          },
          if (onFilter != null)
            const CharacterActivator(FilterKeys.char): const FilterIntent(),
          
          // Inject custom screen-specific overrides
          ...?customShortcuts,
        },
        child: Actions(
          actions: {
            if (onMoveNext != null) MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext!()),
            if (onMovePrev != null) MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev!()),
            if (onMoveLeft != null) MoveLeftIntent: NonTypingAction<MoveLeftIntent>((_) => onMoveLeft!()),
            if (onMoveRight != null) MoveRightIntent: NonTypingAction<MoveRightIntent>((_) => onMoveRight!()),
            if (onFilter != null) FilterIntent: NonTypingAction<FilterIntent>((_) => onFilter!()),
            if (onFocusSearch != null) FocusSearchIntent: NonTypingAction<FocusSearchIntent>((_) => onFocusSearch!()),
            if (onNewItem != null) NewItemIntent: NonTypingAction<NewItemIntent>((_) => onNewItem!()),
            if (onUnfocusSearch != null)
              UnfocusSearchIntent: CallbackAction<UnfocusSearchIntent>(
                onInvoke: (intent) {
                  onUnfocusSearch!();
                  return null;
                },
              ),
            
            // Inject custom screen-specific actions
            ...?customActions,
          },
          child: child,
        ),
      ),
    );
  }
}
