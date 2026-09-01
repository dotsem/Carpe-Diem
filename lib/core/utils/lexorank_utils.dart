class LexoRankUtils {
  static const String defaultRank = 'a0';
  static const String _base62 =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  static int _charToVal(int code) {
    if (code >= 48 && code <= 57) return code - 48; // 0-9 -> 0-9
    if (code >= 65 && code <= 90) return code - 65 + 10; // A-Z -> 10-35
    if (code >= 97 && code <= 122) return code - 97 + 36; // a-z -> 36-61
    return -1;
  }

  static String _encodeInteger(int n) {
    if (n >= 0) {
      if (n < 62) {
        return 'a${_base62[n]}';
      }
      if (n < 62 + 3844) {
        final val = n - 62;
        return 'b${_base62[val ~/ 62]}${_base62[val % 62]}';
      }
      final val = n - (62 + 3844);
      final d1 = (val ~/ 3844) % 62;
      final d2 = (val ~/ 62) % 62;
      final d3 = val % 62;
      return 'c${_base62[d1]}${_base62[d2]}${_base62[d3]}';
    } else {
      final m = -n - 1;
      if (m < 62) {
        return 'Z${_base62[61 - m]}';
      }
      if (m < 62 + 3844) {
        final val = m - 62;
        final inv = 3843 - val;
        return 'Y${_base62[inv ~/ 62]}${_base62[inv % 62]}';
      }
      final val = m - (62 + 3844);
      final inv = 238327 - val;
      final d1 = (inv ~/ 3844) % 62;
      final d2 = (inv ~/ 62) % 62;
      final d3 = inv % 62;
      return 'X${_base62[d1]}${_base62[d2]}${_base62[d3]}';
    }
  }

  static ({int intVal, String intPrefix, String fraction})? _parseKey(
    String key,
  ) {
    if (key.length < 2) return null;
    final head = key.codeUnitAt(0);

    if (head >= 97 && head <= 122) {
      // 'a'..'z'
      final digitCount = head - 97 + 1;
      if (key.length < 1 + digitCount) return null;
      int val = 0;
      for (int i = 0; i < digitCount; i++) {
        final cVal = _charToVal(key.codeUnitAt(1 + i));
        if (cVal < 0) return null;
        val = val * 62 + cVal;
      }
      int intVal = val;
      if (digitCount == 2) intVal += 62;
      if (digitCount == 3) intVal += 62 + 3844;
      return (
        intVal: intVal,
        intPrefix: key.substring(0, 1 + digitCount),
        fraction: key.substring(1 + digitCount),
      );
    } else if (head >= 65 && head <= 90) {
      // 'A'..'Z'
      final digitCount = 90 - head + 1;
      if (key.length < 1 + digitCount) return null;
      int val = 0;
      for (int i = 0; i < digitCount; i++) {
        final cVal = _charToVal(key.codeUnitAt(1 + i));
        if (cVal < 0) return null;
        val = val * 62 + cVal;
      }
      int m;
      if (digitCount == 1) {
        m = 61 - val;
      } else if (digitCount == 2) {
        m = (3843 - val) + 62;
      } else {
        m = (238327 - val) + 62 + 3844;
      }
      final intVal = -m - 1;
      return (
        intVal: intVal,
        intPrefix: key.substring(0, 1 + digitCount),
        fraction: key.substring(1 + digitCount),
      );
    }
    return null;
  }

  static String _midpointFraction(String fracA, String fracB) {
    final sb = StringBuffer();
    int i = 0;

    while (true) {
      final codeA = i < fracA.length ? _charToVal(fracA.codeUnitAt(i)) : 0;
      final codeB = fracB.isNotEmpty && i < fracB.length
          ? _charToVal(fracB.codeUnitAt(i))
          : 62;

      if (codeA == codeB) {
        sb.write(_base62[codeA]);
        i++;
        continue;
      }

      if (codeB - codeA > 1) {
        final mid = codeA + ((codeB - codeA) ~/ 2);
        sb.write(_base62[mid]);
        return sb.toString();
      }

      sb.write(_base62[codeA]);
      i++;
      fracB = '';
    }
  }

  static String generateBetween(String? prev, String? next) {
    if (prev != null && (prev.isEmpty || prev == '~')) prev = null;
    if (next != null && (next.isEmpty || next == '~')) next = null;

    if (prev == null && next == null) return defaultRank;

    final parsedP = prev != null ? _parseKey(prev) : null;
    final parsedN = next != null ? _parseKey(next) : null;

    // Handle legacy fallback if neither is formatted as base62 key
    if ((prev != null && parsedP == null) ||
        (next != null && parsedN == null)) {
      return _legacyBetween(prev, next);
    }

    if (parsedP == null) {
      // generate before next
      final n = parsedN!;
      if (n.fraction.isNotEmpty) {
        return n.intPrefix;
      }
      return _encodeInteger(n.intVal - 1);
    }

    if (parsedN == null) {
      // generate after prev
      final p = parsedP;
      return _encodeInteger(p.intVal + 1);
    }

    if (prev == next) {
      return '${prev}V';
    }

    if (prev!.compareTo(next!) > 0) {
      return generateBetween(next, prev);
    }

    if (parsedP.intVal < parsedN.intVal) {
      if (parsedN.intVal - parsedP.intVal > 1) {
        final midInt =
            parsedP.intVal + ((parsedN.intVal - parsedP.intVal) ~/ 2);
        return _encodeInteger(midInt);
      }
      // Adjacent integers, e.g. a0 and a1 -> interpolate fraction after a0
      final frac = _midpointFraction(parsedP.fraction, '');
      return '${parsedP.intPrefix}$frac';
    }

    // Same integer head -> interpolate fractions
    final frac = _midpointFraction(parsedP.fraction, parsedN.fraction);
    return '${parsedP.intPrefix}$frac';
  }

  static String _legacyBetween(String? prev, String? next) {
    if (prev == null) {
      if (next == null) return defaultRank;
      final firstCode = next.isNotEmpty ? next.codeUnitAt(0) : 109;
      if (firstCode > 48) {
        return String.fromCharCode(48 + ((firstCode - 48) ~/ 2));
      }
      return 'Zz';
    }
    if (next == null) {
      final lastCode = prev.isNotEmpty ? prev.codeUnitAt(0) : 109;
      if (lastCode < 122) {
        return String.fromCharCode(lastCode + ((122 - lastCode) ~/ 2));
      }
      return '${prev}V';
    }
    if (prev == next) return '${prev}V';
    return '${prev}V';
  }

  static String generateTop(String? currentFirst) =>
      generateBetween(null, currentFirst);

  static String generateBottom(String? currentLast) =>
      generateBetween(currentLast, null);

  static String generateMiddle(String? first, String? last) =>
      generateBetween(first, last);
}
