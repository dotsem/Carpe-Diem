import 'package:carpe_diem/features/common/presentation/shortcuts/hardware_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaskFormShortcuts extends StatelessWidget {
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

  void _toggleProjectMenu() {
    if (projectMenuController.isOpen) {
      projectMenuController.close();
    } else {
      projectMenuController.open();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !isControlOrMetaPressed()) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        onSubmit();
        return true;
      case LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1:
        onPlacementChanged(TaskPlacement.bottom);
        return true;
      case LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2:
        onPlacementChanged(TaskPlacement.middle);
        return true;
      case LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3:
        onPlacementChanged(TaskPlacement.top);
        return true;
      case LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4:
        onPlacementChanged(TaskPlacement.urgent);
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
    return HardwareShortcuts(onKeyEvent: _handleKeyEvent, child: child);
  }
}
