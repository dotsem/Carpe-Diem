import 'package:flutter/services.dart';

// Navigation Screens
abstract class TodayKeys {
  static const char = "t";
  static const upper = "T";
  static const keyboardKey = LogicalKeyboardKey.keyT;
}

abstract class BacklogKeys {
  static const char = "b";
  static const upper = "B";
  static const keyboardKey = LogicalKeyboardKey.keyB;
}

abstract class ProjectsKeys {
  static const char = "p";
  static const upper = "P";
  static const keyboardKey = LogicalKeyboardKey.keyP;
}

abstract class HistoryKeys {
  static const char = "i";
  static const upper = "I";
  static const keyboardKey = LogicalKeyboardKey.keyI;
}

// Focus & Traversal
abstract class LeftKeys {
  static const char = "h";
  static const upper = "H";
  static const keyboardKey = LogicalKeyboardKey.keyH;
}

abstract class DownKeys {
  static const char = "j";
  static const upper = "J";
  static const keyboardKey = LogicalKeyboardKey.keyJ;
}

abstract class UpKeys {
  static const char = "k";
  static const upper = "K";
  static const keyboardKey = LogicalKeyboardKey.keyK;
}

abstract class RightKeys {
  static const char = "l";
  static const upper = "L";
  static const keyboardKey = LogicalKeyboardKey.keyL;
}

// Undo/Redo
abstract class UndoKeys {
  static const char = "z";
  static const upper = "Z";
  static const keyboardKey = LogicalKeyboardKey.keyZ;
}

abstract class RedoKeys {
  static const char = "y";
  static const upper = "Y";
  static const keyboardKey = LogicalKeyboardKey.keyY;
}

// Action Triggers
abstract class AddKeys {
  static const char = "a";
  static const upper = "A";
  static const keyboardKey = LogicalKeyboardKey.keyA;
}

abstract class ToggleLayoutKeys {
  static const char = "v";
  static const upper = "V";
  static const keyboardKey = LogicalKeyboardKey.keyV;
}

abstract class FilterKeys {
  static const char = "f";
  static const upper = "F";
  static const keyboardKey = LogicalKeyboardKey.keyF;
}

abstract class SearchKeys {
  static const char = "/";
  static const keyboardKey = LogicalKeyboardKey.slash;
}

abstract class HelpKeys {
  static const char = "?";
}

abstract class EditKeys {
  static const char = "e";
  static const keyboardKey = LogicalKeyboardKey.keyE;
}

abstract class DeleteKeys {
  static const char = "d";
  static const keyboardKey = LogicalKeyboardKey.keyD;
}

// Common Non-Character Keys & Registry
class AppKeyBindings {
  static const escape = LogicalKeyboardKey.escape;
  static const enter = LogicalKeyboardKey.enter;

  // Arrow Keys
  static const arrowLeft = LogicalKeyboardKey.arrowLeft;
  static const arrowDown = LogicalKeyboardKey.arrowDown;
  static const arrowUp = LogicalKeyboardKey.arrowUp;
  static const arrowRight = LogicalKeyboardKey.arrowRight;

  // Priority Digits
  static const digit1 = LogicalKeyboardKey.digit1;
  static const digit2 = LogicalKeyboardKey.digit2;
  static const digit3 = LogicalKeyboardKey.digit3;
  static const digit4 = LogicalKeyboardKey.digit4;
  static const digit5 = LogicalKeyboardKey.digit5;
}
