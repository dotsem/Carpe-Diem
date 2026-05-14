import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/ui/shortcuts/shortcuts_help_overlay.dart';

class NavigateToTodayIntent extends Intent {
  const NavigateToTodayIntent();
}

class NavigateToBacklogIntent extends Intent {
  const NavigateToBacklogIntent();
}

class NavigateToProjectsIntent extends Intent {
  const NavigateToProjectsIntent();
}

class NavigateToHistoryIntent extends Intent {
  const NavigateToHistoryIntent();
}

class ToggleHelpIntent extends Intent {
  const ToggleHelpIntent();
}

class CloseHelpIntent extends Intent {
  const CloseHelpIntent();
}

class MoveNextIntent extends Intent {
  const MoveNextIntent();
}

class MovePrevIntent extends Intent {
  const MovePrevIntent();
}

class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

class FilterIntent extends Intent {
  const FilterIntent();
}

class ShortcutEntry {
  final String key;
  final String description;
  final String category;

  const ShortcutEntry({required this.key, required this.description, required this.category});
}

const globalShortcutEntries = [
  ShortcutEntry(key: 'T', description: 'Go to Today', category: 'Navigation'),
  ShortcutEntry(key: 'B', description: 'Go to Backlog', category: 'Navigation'),
  ShortcutEntry(key: 'P', description: 'Go to Projects', category: 'Navigation'),
  ShortcutEntry(key: 'Y', description: 'Go to History', category: 'Navigation'),
  ShortcutEntry(key: 'j', description: 'Move Focus Down', category: 'Navigation'),
  ShortcutEntry(key: 'k', description: 'Move Focus Up', category: 'Navigation'),
  ShortcutEntry(key: '?', description: 'Toggle shortcut help', category: 'Global'),
  ShortcutEntry(key: 'Alt', description: 'Hold to show hints', category: 'Global'),
];

const homeShortcutEntries = [
  ShortcutEntry(key: 'h / l', description: 'Prev / Next day', category: 'Today View'),
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Today View'),
  ShortcutEntry(key: 'n', description: 'Add new task', category: 'Today View'),
  ShortcutEntry(key: 'v', description: 'Toggle layout', category: 'Today View'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Today View'),
];

const taskCardShortcutEntries = [
  ShortcutEntry(key: 'Space', description: 'Toggle completion', category: 'Focused Task'),
  ShortcutEntry(key: 'Enter', description: 'Toggle completion', category: 'Focused Task'),
  ShortcutEntry(key: 'e', description: 'Edit task', category: 'Focused Task'),
  ShortcutEntry(key: 'd', description: 'Delete task', category: 'Focused Task'),
];

const projectShortcutEntries = [
  ShortcutEntry(key: 'h / j / k / l', description: 'Move focus', category: 'Projects View'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Projects View'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Projects View'),
];

const taskDialogShortcutEntries = [
  ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Task Editor'),
  ShortcutEntry(key: 'Ctrl + P', description: 'Open project menu', category: 'Task Editor'),
  ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Task Editor'),
  ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Task Editor'),
];

const projectDialogShortcutEntries = [
  ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Project Editor'),
  ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Project Editor'),
  ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Project Editor'),
];

const backlogShortcutEntries = [
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Backlog'),
  ShortcutEntry(key: 'n', description: 'Add new task', category: 'Backlog'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Backlog'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Backlog'),
];

const projectDetailShortcutEntries = [
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Project Detail'),
  ShortcutEntry(key: 'n', description: 'Add new task', category: 'Project Detail'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Project Detail'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Project Detail'),
];

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

class GlobalShortcuts extends StatefulWidget {
  final Widget child;

  const GlobalShortcuts({super.key, required this.child});

  @override
  State<GlobalShortcuts> createState() => GlobalShortcutsState();

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

class GlobalShortcutsState extends State<GlobalShortcuts> {
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
          const CharacterActivator('T'): const NavigateToTodayIntent(),
          const CharacterActivator('B'): const NavigateToBacklogIntent(),
          const CharacterActivator('P'): const NavigateToProjectsIntent(),
          const CharacterActivator('Y'): const NavigateToHistoryIntent(),
          const CharacterActivator('t'): const NavigateToTodayIntent(),
          const CharacterActivator('b'): const NavigateToBacklogIntent(),
          const CharacterActivator('p'): const NavigateToProjectsIntent(),
          const CharacterActivator('y'): const NavigateToHistoryIntent(),
          const CharacterActivator('?'): const ToggleHelpIntent(),
          const SingleActivator(LogicalKeyboardKey.escape): const CloseHelpIntent(),
          const CharacterActivator('j'): const MoveNextIntent(),
          const CharacterActivator('k'): const MovePrevIntent(),
          const CharacterActivator('J'): const MoveNextIntent(),
          const CharacterActivator('K'): const MovePrevIntent(),
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
              context.go('/');
            }),
            NavigateToBacklogIntent: NonTypingAction<NavigateToBacklogIntent>((intent) {
              debugPrint('Shortcut: NavigateToBacklog');
              context.go('/tasks');
            }),
            NavigateToProjectsIntent: NonTypingAction<NavigateToProjectsIntent>((intent) {
              debugPrint('Shortcut: NavigateToProjects');
              context.go('/projects');
            }),
            NavigateToHistoryIntent: NonTypingAction<NavigateToHistoryIntent>((intent) {
              debugPrint('Shortcut: NavigateToHistory');
              context.go('/history');
            }),
            ToggleHelpIntent: NonTypingAction<ToggleHelpIntent>((intent) {
              debugPrint('Shortcut: ToggleHelp');
              toggleHelp();
            }),
            CloseHelpIntent: CallbackAction<CloseHelpIntent>(
              onInvoke: (intent) {
                debugPrint('Shortcut: CloseHelp');
                closeHelp();
                return null;
              },
            ),
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
