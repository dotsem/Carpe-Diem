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
  ShortcutEntry(key: 'j', description: 'Move Focus Down', category: 'Navigation'),
  ShortcutEntry(key: 'k', description: 'Move Focus Up', category: 'Navigation'),
  ShortcutEntry(key: '?', description: 'Toggle shortcut help', category: 'Global'),
  ShortcutEntry(key: 'Alt', description: 'Hold to show hints', category: 'Global'),
];

const homeShortcutEntries = [
  ShortcutEntry(key: 'h', description: 'Previous day', category: 'Today'),
  ShortcutEntry(key: 'l', description: 'Next day', category: 'Today'),
  ShortcutEntry(key: 'j', description: 'Focus next task', category: 'Today'),
  ShortcutEntry(key: 'k', description: 'Focus previous task', category: 'Today'),
  ShortcutEntry(key: 'n', description: 'Add new task', category: 'Today'),
  ShortcutEntry(key: 'v', description: 'Toggle layout', category: 'Today'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Today'),
];

const taskCardShortcutEntries = [
  ShortcutEntry(key: 'Space', description: 'Toggle completion', category: 'Task (focused)'),
  ShortcutEntry(key: 'Enter', description: 'Toggle completion', category: 'Task (focused)'),
  ShortcutEntry(key: 'e', description: 'Edit task', category: 'Task (focused)'),
  ShortcutEntry(key: 'd', description: 'Delete task', category: 'Task (focused)'),
];

List<ShortcutEntry> get allShortcutEntries => [
  ...globalShortcutEntries,
  ...homeShortcutEntries,
  ...taskCardShortcutEntries,
];
bool isTypingInTextField() {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  if (context == null) return false;

  final widget = context.widget;
  if (widget is EditableText || widget is TextField || widget is TextFormField) {
    return true;
  }

  bool isTextInput = false;
  context.visitAncestorElements((element) {
    final ancestorWidget = element.widget;
    if (ancestorWidget is EditableText || ancestorWidget is TextField || ancestorWidget is TextFormField) {
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
    return null;
  }
}

class GlobalShortcuts extends StatefulWidget {
  final Widget child;

  const GlobalShortcuts({super.key, required this.child});

  @override
  State<GlobalShortcuts> createState() => GlobalShortcutsState();

  static GlobalShortcutsState of(BuildContext context) {
    return context.findAncestorStateOfType<GlobalShortcutsState>()!;
  }
}

class GlobalShortcutsState extends State<GlobalShortcuts> {
  final _overlayKey = GlobalKey<ShortcutsHelpOverlayState>();
  bool _helpVisible = false;
  bool _isAltPressed = false;

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
          const CharacterActivator('t'): const NavigateToTodayIntent(),
          const CharacterActivator('b'): const NavigateToBacklogIntent(),
          const CharacterActivator('p'): const NavigateToProjectsIntent(),
          const CharacterActivator('?'): const ToggleHelpIntent(),
          const SingleActivator(LogicalKeyboardKey.escape): const CloseHelpIntent(),
          const CharacterActivator('j'): const DirectionalFocusIntent(TraversalDirection.down),
          const CharacterActivator('k'): const DirectionalFocusIntent(TraversalDirection.up),
          const CharacterActivator('J'): const DirectionalFocusIntent(TraversalDirection.down),
          const CharacterActivator('K'): const DirectionalFocusIntent(TraversalDirection.up),
        },
        child: Actions(
          actions: {
            DirectionalFocusIntent: NonTypingAction<DirectionalFocusIntent>((intent) {
              debugPrint('Shortcut: DirectionalFocus ${intent.direction}');
              FocusManager.instance.primaryFocus?.focusInDirection(intent.direction);
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
