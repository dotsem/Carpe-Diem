import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectFormShortcuts extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onUrgencyChanged;
  final VoidCallback onSubmit;

  const ProjectFormShortcuts({
    super.key,
    required this.child,
    required this.onUrgencyChanged,
    required this.onSubmit,
  });

  @override
  State<ProjectFormShortcuts> createState() => _ProjectFormShortcutsState();
}

class _ProjectFormShortcutsState extends State<ProjectFormShortcuts> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    if (!isCtrl && !isMeta) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        widget.onSubmit();
        return true;
      case LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1:
        widget.onUrgencyChanged(false);
        return true;
      case LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2:
        widget.onUrgencyChanged(true);
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
