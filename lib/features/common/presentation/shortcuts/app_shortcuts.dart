import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcuts_help_overlay.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_intents.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_intents.dart';
export 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
export 'package:carpe_diem/features/common/presentation/shortcuts/base_screen_shortcuts.dart';

bool isTypingInTextField() {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  if (context == null) return false;

  bool isTextInput = false;

  // Check if the focused widget itself is a text input
  final widget = context.widget;
  if (widget is EditableText || widget is TextField || widget is TextFormField) {
    return true;
  }

  // Visit ancestors to find if we're inside a text input widget
  context.visitAncestorElements((element) {
    final ancestorWidget = element.widget;
    if (ancestorWidget is EditableText || ancestorWidget is TextField || ancestorWidget is TextFormField) {
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

  const GlobalShortcuts({super.key, required this.child});

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

  List<ShortcutEntry> get contextualShortcuts => _contextualShortcuts.values.expand((e) => e).toList();

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
    final isAlt = event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight;

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
        shortcuts: {
          const CharacterActivator(TodayKeys.upper): const NavigateToTodayIntent(),
          const CharacterActivator(BacklogKeys.upper): const NavigateToBacklogIntent(),
          const CharacterActivator(ProjectsKeys.upper): const NavigateToProjectsIntent(),
          const CharacterActivator(HistoryKeys.upper): const NavigateToHistoryIntent(),
          const CharacterActivator(TodayKeys.char): const NavigateToTodayIntent(),
          const CharacterActivator(BacklogKeys.char): const NavigateToBacklogIntent(),
          const CharacterActivator(ProjectsKeys.char): const NavigateToProjectsIntent(),
          const CharacterActivator(HistoryKeys.char): const NavigateToHistoryIntent(),
          const CharacterActivator(HelpKeys.char): const ToggleHelpIntent(),
          const CharacterActivator(FilterKeys.upper): const ToggleFilterBypassIntent(),
          const SingleActivator(AppKeyBindings.escape): const CloseHelpIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const CharacterActivator(DownKeys.upper): const MoveNextIntent(),
          const CharacterActivator(UpKeys.upper): const MovePrevIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((intent) {
              debugPrint('Shortcut: MoveNext');
              FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down);
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((intent) {
              debugPrint('Shortcut: MovePrev');
              FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.up);
            }),
            NavigateToTodayIntent: NonTypingAction<NavigateToTodayIntent>((intent) {
              debugPrint('Shortcut: NavigateToToday');
              appRouter.go('/');
            }),
            NavigateToBacklogIntent: NonTypingAction<NavigateToBacklogIntent>((intent) {
              debugPrint('Shortcut: NavigateToBacklog');
              appRouter.go('/tasks');
            }),
            NavigateToProjectsIntent: NonTypingAction<NavigateToProjectsIntent>((intent) {
              debugPrint('Shortcut: NavigateToProjects');
              appRouter.go('/projects');
            }),
            NavigateToHistoryIntent: NonTypingAction<NavigateToHistoryIntent>((intent) {
              debugPrint('Shortcut: NavigateToHistory');
              appRouter.go('/history');
            }),
            ToggleHelpIntent: NonTypingAction<ToggleHelpIntent>((intent) {
              debugPrint('Shortcut: ToggleHelp');
              toggleHelp();
            }),
            CloseHelpIntent: _CloseHelpAction(this),
            ToggleFilterBypassIntent: NonTypingAction<ToggleFilterBypassIntent>((intent) {
              debugPrint('Shortcut: ToggleFilterBypass');
              ref.read(filterProvider.notifier).toggleBypass();
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

  const AppShortcutRegistrar({super.key, required this.shortcuts, required this.child});

  @override
  State<AppShortcutRegistrar> createState() => _AppShortcutRegistrarState();
}

class _AppShortcutRegistrarState extends State<AppShortcutRegistrar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GlobalShortcuts.of(context).register(this, widget.shortcuts);
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
