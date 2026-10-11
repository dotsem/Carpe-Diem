import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/hardware_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectFormShortcuts extends StatelessWidget {
  final Widget child;
  final ValueChanged<bool> onUrgencyChanged;
  final MenuController labelMenuController;
  final VoidCallback onSubmit;

  const ProjectFormShortcuts({
    super.key,
    required this.child,
    required this.onUrgencyChanged,
    required this.labelMenuController,
    required this.onSubmit,
  });

  void _toggleMenu(MenuController? controller) {
    if (controller == null) return;
    if (controller.isOpen) {
      controller.close();
    } else {
      // _closeOthers(controller); // not yet needed
      controller.open();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !isControlOrMetaPressed()) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        onSubmit();
        return true;
      case LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1:
        onUrgencyChanged(false);
        return true;
      case LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2:
        onUrgencyChanged(true);
        return true;
      case LabelsKeys.keyboardKey:
        _toggleMenu(labelMenuController);
        return true;

      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcutRegistrar(
      shortcuts: projectDialogShortcutEntries,
      child: HardwareShortcuts(onKeyEvent: _handleKeyEvent, child: child),
    );
  }
}
