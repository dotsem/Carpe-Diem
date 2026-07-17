class TagParser {
  static final RegExp _tagRegExp = RegExp(r'(^|\s)#([a-zA-Z0-9_\-]+)');

  /// Parses all tag names (without the # prefix) from the text.
  /// Returns a list of unique, lowercase, trimmed tag names.
  static List<String> parseTags(String text) {
    final matches = _tagRegExp.allMatches(text);
    final tags = <String>{};
    for (final match in matches) {
      final name = match.group(2);
      if (name != null && name.trim().isNotEmpty) {
        tags.add(name.trim().toLowerCase());
      }
    }
    return tags.toList();
  }

  /// Strips all hashtags from the text and cleans up whitespace.
  static String stripTags(String text) {
    var cleaned = text.replaceAllMapped(_tagRegExp, (m) => m.group(1)!);
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Checks if a specific hashtag exists in the text.
  static bool containsTag(String text, String tagName) {
    final RegExp tagRegex = RegExp(r'(^|\s)#' + RegExp.escape(tagName) + r'(?![a-zA-Z0-9_\-])', caseSensitive: false);
    return tagRegex.hasMatch(text);
  }

  /// Renames a specific hashtag in the text to a new name.
  static String renameSpecificTag(String text, String oldTagName, String newTagName) {
    final RegExp tagRegex = RegExp(
      r'(^|\s)#' + RegExp.escape(oldTagName) + r'(?![a-zA-Z0-9_\-])',
      caseSensitive: false,
    );
    return text.replaceAllMapped(tagRegex, (m) => '${m.group(1)}#$newTagName');
  }

  /// Strips specific hashtags from the text and cleans up whitespace.
  static String stripSpecificTags(String text, List<String> tagNamesToStrip) {
    var cleaned = text;
    for (final name in tagNamesToStrip) {
      final RegExp tagRegex = RegExp(r'(^|\s)#' + RegExp.escape(name) + r'(?![a-zA-Z0-9_\-])', caseSensitive: false);
      cleaned = cleaned.replaceAllMapped(tagRegex, (m) => m.group(1)!);
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Gets the active hashtag query and its start/end index in the text based on cursor selection.
  /// Returns null if cursor is not at/within a hashtag word.
  static HashtagQuery? getActiveQuery(String text, int selectionIndex) {
    if (selectionIndex < 0 || selectionIndex > text.length) return null;

    var start = selectionIndex;
    while (start > 0 && !_isWhitespace(text[start - 1])) {
      start--;
    }

    var end = selectionIndex;
    while (end < text.length && !_isWhitespace(text[end])) {
      end++;
    }

    final word = text.substring(start, end);
    if (word.startsWith('#') && word.length > 1) {
      return HashtagQuery(query: word.substring(1), startIndex: start, endIndex: end);
    }
    if (word == '#') {
      return HashtagQuery(query: '', startIndex: start, endIndex: end);
    }

    return null;
  }

  static bool _isWhitespace(String char) {
    return char == ' ' || char == '\n' || char == '\r' || char == '\t';
  }
}

class HashtagQuery {
  final String query;
  final int startIndex;
  final int endIndex;

  const HashtagQuery({required this.query, required this.startIndex, required this.endIndex});
}
