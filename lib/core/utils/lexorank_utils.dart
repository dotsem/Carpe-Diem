class LexoRankUtils {
  static const int _minChar = 48; // '0'
  static const int _maxChar = 122; // 'z'
  static const String defaultRank = 'm';

  static String generateBetween(String? prev, String? next) {
    if (prev == null || prev.isEmpty) {
      if (next == null || next.isEmpty) {
        return defaultRank;
      }
      return _between('', next);
    }
    if (next == null || next.isEmpty) {
      return _between(prev, '');
    }
    if (prev == next) {
      return '${prev}m';
    }
    if (prev.compareTo(next) > 0) {
      return _between(next, prev);
    }
    return _between(prev, next);
  }

  static String _between(String p, String n) {
    int pos = 0;
    final sb = StringBuffer();

    while (true) {
      final pChar = pos < p.length ? p.codeUnitAt(pos) : _minChar;
      final nChar = n.isNotEmpty && pos < n.length ? n.codeUnitAt(pos) : _maxChar;

      if (pChar == nChar) {
        sb.writeCharCode(pChar);
        pos++;
        continue;
      }

      if (nChar - pChar > 1) {
        final mid = pChar + ((nChar - pChar) ~/ 2);
        sb.writeCharCode(mid);
        return sb.toString();
      }

      sb.writeCharCode(pChar);
      pos++;
      final pNextChar = pos < p.length ? p.codeUnitAt(pos) : _minChar;
      final mid = pNextChar + ((_maxChar - pNextChar) ~/ 2);
      sb.writeCharCode(mid);
      return sb.toString();
    }
  }

  static String generateTop(String? currentFirst) {
    return generateBetween(null, currentFirst);
  }

  static String generateBottom(String? currentLast) {
    return generateBetween(currentLast, null);
  }

  static String generateMiddle(String? first, String? last) {
    return generateBetween(first, last);
  }

  static String computeReorderSortOrder<T>(
    List<T> list,
    int oldIndex,
    int newIndex,
    String Function(T) getSortOrder,
  ) {
    if (list.isEmpty) return defaultRank;
    final remaining = List<T>.from(list)..removeAt(oldIndex);
    int adjustedIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;

    if (remaining.isEmpty) return defaultRank;
    if (adjustedIndex <= 0) {
      return generateTop(getSortOrder(remaining.first));
    }
    if (adjustedIndex >= remaining.length) {
      return generateBottom(getSortOrder(remaining.last));
    }

    final prev = getSortOrder(remaining[adjustedIndex - 1]);
    final next = getSortOrder(remaining[adjustedIndex]);
    return generateBetween(prev, next);
  }
}
