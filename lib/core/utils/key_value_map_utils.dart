extension KeyValueMapUtils on Map<String, String> {
  String getString(String key, String defaultValue) =>
      this[key] ?? defaultValue;

  int getInt(String key, int defaultValue) =>
      int.tryParse(this[key] ?? '') ?? defaultValue;

  double getDouble(String key, double defaultValue) =>
      double.tryParse(this[key] ?? '') ?? defaultValue;

  bool getBool(String key, bool defaultValue) =>
      (this[key] ?? defaultValue.toString()) == 'true';

  T getEnum<T extends Enum>(String key, List<T> values, T defaultValue) {
    final valueStr = this[key];
    if (valueStr == null) return defaultValue;
    return values.firstWhere(
      (e) => e.name == valueStr,
      orElse: () => defaultValue,
    );
  }
}
