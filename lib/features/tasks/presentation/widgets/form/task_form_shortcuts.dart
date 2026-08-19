import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaskFormShortcuts extends StatefulWidget {
  final Widget child;
  final ValueChanged<TaskPlacement> onPlacementChanged;
  final MenuController projectMenuController;
  final VoidCallback onSubmit;

  const TaskFormShortcuts({
    super.key,
    required this.child,
    required this.onPlacementChanged,
    required this.projectMenuController,
    required this.onSubmit,
  });

  @override
  State<TaskFormShortcuts> createState() => _TaskFormShortcutsState();
}

class _TaskFormShortcutsState extends State<TaskFormShortcuts> {
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

  void _toggleProjectMenu() {
    if (widget.projectMenuController.isOpen) {
      widget.projectMenuController.close();
    } else {
      widget.projectMenuController.open();
    }
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
        widget.onPlacementChanged(TaskPlacement.bottom);
        return true;
      case LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2:
        widget.onPlacementChanged(TaskPlacement.middle);
        return true;
      case LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3:
        widget.onPlacementChanged(TaskPlacement.top);
        return true;
      case LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4:
        widget.onPlacementChanged(TaskPlacement.urgent);
        return true;
      case ProjectsKeys.keyboardKey:
        _toggleProjectMenu();
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
