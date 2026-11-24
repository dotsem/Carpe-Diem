import 'package:flutter/services.dart';

export 'package:dotmaterial/dotmaterial.dart' show isControlOrMetaPressed;

// Navigation Screens
abstract class TodayKeys {
  static const char = 't';
  static const upper = 'T';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyT;
}

abstract class BacklogKeys {
  static const char = 'b';
  static const upper = 'B';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyB;
}

abstract class ProjectsKeys {
  static const char = 'p';
  static const upper = 'P';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyP;
}

abstract class HistoryKeys {
  static const char = 'i';
  static const upper = 'I';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyI;
}

// Focus & Traversal
abstract class LeftKeys {
  static const char = 'h';
  static const upper = 'H';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyH;
}

abstract class DownKeys {
  static const char = 'j';
  static const upper = 'J';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyJ;
}

abstract class UpKeys {
  static const char = 'k';
  static const upper = 'K';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyK;
}

abstract class RightKeys {
  static const char = 'l';
  static const upper = 'L';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyL;
}

// Undo/Redo
abstract class UndoKeys {
  static const char = 'z';
  static const upper = 'Z';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyZ;
}

abstract class RedoKeys {
  static const char = 'y';
  static const upper = 'Y';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyY;
}

// Action Triggers
abstract class AddKeys {
  static const char = 'a';
  static const upper = 'A';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyA;
}

abstract class ToggleLayoutKeys {
  static const char = 'v';
  static const upper = 'V';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyV;
}

abstract class FilterKeys {
  static const char = 'f';
  static const upper = 'F';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyF;
}

abstract class ModeKeys {
  static const char = 'm';
  static const upper = 'M';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyM;
}

abstract class SearchKeys {
  static const char = '/';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.slash;
}

abstract class HelpKeys {
  static const char = '?';
}

abstract class EditKeys {
  static const char = 'e';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyE;
}

abstract class DeleteKeys {
  static const char = 'd';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyD;
}

abstract class BlockersKeys {
  static const char = 'b';
  static const upper = 'B';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyB;
}

abstract class LabelsKeys {
  static const char = 'l';
  static const upper = 'L';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyL;
}

abstract class TagsKeys {
  static const char = 't';
  static const upper = 'T';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyT;
}

abstract class SubtaskKeys {
  static const char = 'n';
  static const upper = 'N';
  static const LogicalKeyboardKey keyboardKey = LogicalKeyboardKey.keyN;
}

// Common Non-Character Keys & Registry
class AppKeyBindings {
  static const LogicalKeyboardKey escape = LogicalKeyboardKey.escape;
  static const LogicalKeyboardKey enter = LogicalKeyboardKey.enter;
  static const LogicalKeyboardKey numpadEnter = LogicalKeyboardKey.numpadEnter;

  // Arrow Keys
  static const LogicalKeyboardKey arrowLeft = LogicalKeyboardKey.arrowLeft;
  static const LogicalKeyboardKey arrowDown = LogicalKeyboardKey.arrowDown;
  static const LogicalKeyboardKey arrowUp = LogicalKeyboardKey.arrowUp;
  static const LogicalKeyboardKey arrowRight = LogicalKeyboardKey.arrowRight;

  // Placement / Urgency Digits
  static const LogicalKeyboardKey digit1 = LogicalKeyboardKey.digit1;
  static const LogicalKeyboardKey digit2 = LogicalKeyboardKey.digit2;
  static const LogicalKeyboardKey digit3 = LogicalKeyboardKey.digit3;
  static const LogicalKeyboardKey digit4 = LogicalKeyboardKey.digit4;
}
