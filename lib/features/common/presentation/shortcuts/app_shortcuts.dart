import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_intents.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcuts_help_overlay.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/mode_selection_dialog.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:carpe_diem/features/common/presentation/shortcuts/base_screen_shortcuts.dart';
export 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_intents.dart';
export 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';

bool isTypingInTextField() {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  if (context == null) return false;

  var isTextInput = false;

  // Check if the focused widget itself is a text input
  final widget = context.widget;
  if (widget is EditableText ||
      widget is TextField ||
      widget is TextFormField) {
    return true;
  }

  // Visit ancestors to find if we're inside a text input widget
  context.visitAncestorElements((element) {
    final ancestorWidget = element.widget;
    if (ancestorWidget is EditableText ||
        ancestorWidget is TextField ||
        ancestorWidget is TextFormField) {
      isTextInput = true;
      return false;
    }
    if (element is StatefulElement && element.state is EditableTextState) {
      isTextInput = true;
      return false;
    }
    return true;
  });

  return isTextInput;
}

class NonTypingAction<T extends Intent> extends Action<T> {
  final void Function(T intent) onInvokeCallback;

  NonTypingAction(this.onInvokeCallback);

  @override
  bool isEnabled(T intent) => !isTypingInTextField();

  @override
  Object? invoke(T intent) {
    onInvokeCallback(intent);
    return intent;
  }
}

class GlobalShortcuts extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalShortcuts({required this.child, super.key});

  @override
  ConsumerState<GlobalShortcuts> createState() => GlobalShortcutsState();

  static GlobalShortcutsState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<GlobalShortcutsState>();
  }

  static GlobalShortcutsState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw FlutterError(
        'GlobalShortcuts.of() called with a context that does not contain a GlobalShortcuts.\n'
        'The context used was: $context',
      );
    }
    return state;
  }
}

class GlobalShortcutsState extends ConsumerState<GlobalShortcuts> {
  final _overlayKey = GlobalKey<ShortcutsHelpOverlayState>();
  bool _helpVisible = false;
  bool _isAltPressed = false;
  final Map<Object, List<ShortcutEntry>> _contextualShortcuts = {};

  void register(Object key, List<ShortcutEntry> shortcuts) {
    _contextualShortcuts[key] = shortcuts;
    if (_helpVisible) _overlayKey.currentState?.updateContent();
  }

  void unregister(Object key) {
    _contextualShortcuts.remove(key);
    if (_helpVisible) _overlayKey.currentState?.updateContent();
  }

  List<ShortcutEntry> get contextualShortcuts =>
      _contextualShortcuts.values.expand((e) => e).toList();

  void toggleHelp() {
    setState(() => _helpVisible = !_helpVisible);
    _updateOverlay();
  }

  void closeHelp() {
    setState(() => _helpVisible = false);
    _updateOverlay();
  }

  void _updateOverlay() {
    if (_helpVisible || _isAltPressed) {
      _overlayKey.currentState?.show();
    } else {
      _overlayKey.currentState?.hide();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    final isAlt =
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight;

    if (isAlt) {
      if (event is KeyDownEvent && !_isAltPressed) {
        setState(() => _isAltPressed = true);
        _updateOverlay();
      } else if (event is KeyUpEvent && _isAltPressed) {
        setState(() => _isAltPressed = false);
        _updateOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: _handleKeyEvent,
      child: Shortcuts(
        shortcuts: const {
          CharacterActivator(TodayKeys.upper): NavigateToTodayIntent(),
          CharacterActivator(BacklogKeys.upper): NavigateToBacklogIntent(),
          CharacterActivator(ProjectsKeys.upper): NavigateToProjectsIntent(),
          CharacterActivator(HistoryKeys.upper): NavigateToHistoryIntent(),
          CharacterActivator(TodayKeys.char): NavigateToTodayIntent(),
          CharacterActivator(BacklogKeys.char): NavigateToBacklogIntent(),
          CharacterActivator(ProjectsKeys.char): NavigateToProjectsIntent(),
          CharacterActivator(HistoryKeys.char): NavigateToHistoryIntent(),
          CharacterActivator(HelpKeys.char): ToggleHelpIntent(),
          CharacterActivator(ModeKeys.char): SwitchModeIntent(),
          CharacterActivator(ModeKeys.upper): SwitchModeIntent(),
          CharacterActivator(FilterKeys.upper): ToggleFilterBypassIntent(),
          SingleActivator(AppKeyBindings.escape): CloseHelpIntent(),
          CharacterActivator(DownKeys.char): MoveNextIntent(),
          CharacterActivator(UpKeys.char): MovePrevIntent(),
          CharacterActivator(DownKeys.upper): MoveNextIntent(),
          CharacterActivator(UpKeys.upper): MovePrevIntent(),
          SingleActivator(AppKeyBindings.arrowDown): MoveNextIntent(),
          SingleActivator(AppKeyBindings.arrowUp): MovePrevIntent(),

          CharacterActivator(UndoKeys.char, control: true): UndoIntent(),
          CharacterActivator(RedoKeys.char, control: true): RedoIntent(),

          // TODO: may remove ctrl+k
          SingleActivator(LogicalKeyboardKey.keyK, control: true):
              OpenCommandPaletteIntent(),
          SingleActivator(LogicalKeyboardKey.keyK, meta: true):
              OpenCommandPaletteIntent(),
          SingleActivator(LogicalKeyboardKey.keyP, control: true):
              OpenCommandPaletteIntent(),
          SingleActivator(LogicalKeyboardKey.keyP, meta: true):
              OpenCommandPaletteIntent(),
        },
        child: Actions(
          actions: {
            OpenCommandPaletteIntent: NonTypingAction<OpenCommandPaletteIntent>(
              (intent) {
                debugPrint('Shortcut: OpenCommandPalette');
                CommandPalette.show();
              },
            ),
            SwitchModeIntent: NonTypingAction<SwitchModeIntent>((intent) {
              debugPrint('Shortcut: SwitchMode');
              ModeSelectionDialog.show();
            }),
            MoveNextIntent: NonTypingAction<MoveNextIntent>((intent) {
              debugPrint('Shortcut: MoveNext');
              FocusManager.instance.primaryFocus?.focusInDirection(
                TraversalDirection.down,
              );
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((intent) {
              debugPrint('Shortcut: MovePrev');
              FocusManager.instance.primaryFocus?.focusInDirection(
                TraversalDirection.up,
              );
            }),
            NavigateToTodayIntent: NonTypingAction<NavigateToTodayIntent>((
              intent,
            ) {
              debugPrint('Shortcut: NavigateToToday');
              appRouter.go('/');
            }),
            NavigateToBacklogIntent: NonTypingAction<NavigateToBacklogIntent>((
              intent,
            ) {
              debugPrint('Shortcut: NavigateToBacklog');
              appRouter.go('/tasks');
            }),
            NavigateToProjectsIntent: NonTypingAction<NavigateToProjectsIntent>(
              (intent) {
                debugPrint('Shortcut: NavigateToProjects');
                appRouter.go('/projects');
              },
            ),
            NavigateToHistoryIntent: NonTypingAction<NavigateToHistoryIntent>((
              intent,
            ) {
              debugPrint('Shortcut: NavigateToHistory');
              appRouter.go('/history');
            }),
            ToggleHelpIntent: NonTypingAction<ToggleHelpIntent>((intent) {
              debugPrint('Shortcut: ToggleHelp');
              toggleHelp();
            }),
            CloseHelpIntent: _CloseHelpAction(this),
            ToggleFilterBypassIntent: NonTypingAction<ToggleFilterBypassIntent>(
              (intent) {
                debugPrint('Shortcut: ToggleFilterBypass');
                ref.read(filterProvider.notifier).toggleBypass();
              },
            ),
            UndoIntent: NonTypingAction<UndoIntent>((intent) {
              debugPrint('Shortcut: Undo');
              ref.read(undoRedoProvider.notifier).undo();
            }),
            RedoIntent: NonTypingAction<RedoIntent>((intent) {
              debugPrint('Shortcut: Redo');
              ref.read(undoRedoProvider.notifier).redo();
            }),
          },
          child: Focus(
            autofocus: true,
            debugLabel: 'GlobalShortcutsFocus',
            child: Stack(
              children: [
                widget.child,
                ShortcutsHelpOverlay(key: _overlayKey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShortcutRegistrar extends StatefulWidget {
  final List<ShortcutEntry> shortcuts;
  final Widget child;

  const AppShortcutRegistrar({
    required this.shortcuts,
    required this.child,
    super.key,
  });

  @override
  State<AppShortcutRegistrar> createState() => _AppShortcutRegistrarState();
}

class _AppShortcutRegistrarState extends State<AppShortcutRegistrar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GlobalShortcuts.maybeOf(context)?.register(this, widget.shortcuts);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = GlobalShortcuts.maybeOf(context);
  }

  GlobalShortcutsState? _state;

  @override
  void deactivate() {
    _state?.unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CloseHelpAction extends Action<CloseHelpIntent> {
  final GlobalShortcutsState state;

  _CloseHelpAction(this.state);

  @override
  bool isEnabled(CloseHelpIntent intent) => state._helpVisible;

  @override
  Object? invoke(CloseHelpIntent intent) {
    debugPrint('Shortcut: CloseHelp');
    state.closeHelp();
    return intent;
  }
}
