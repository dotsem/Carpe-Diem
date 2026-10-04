const illegalModeNames = <String>{'custom', 'no mode', 'no_mode', 'no-mode'};

bool isIllegalModeName(String name) {
  return illegalModeNames.contains(name.toLowerCase());
}
