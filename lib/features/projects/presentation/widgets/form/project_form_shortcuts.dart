import 'package:carpe_diem/features/common/presentation/shortcuts/hardware_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectFormShortcuts extends StatelessWidget {
  final Widget child;
  final ValueChanged<bool> onUrgencyChanged;
  final VoidCallback onSubmit;

  const ProjectFormShortcuts({
    super.key,
    required this.child,
    required this.onUrgencyChanged,
    required this.onSubmit,
  });

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
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HardwareShortcuts(onKeyEvent: _handleKeyEvent, child: child);
  }
}
