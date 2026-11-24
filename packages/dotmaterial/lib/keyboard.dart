import 'package:flutter/services.dart';

/// Whether Ctrl (Windows/Linux) or Cmd (macOS) is currently held.
bool isControlOrMetaPressed() {
  return HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed;
}
