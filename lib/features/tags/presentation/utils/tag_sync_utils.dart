import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class TagSyncUtils {
  /// Appends a hashtag to the text if it's not already present.
  static String addTagToText(String text, String tagName, {TagAppendPosition position = AppConstants.defaultTagAppendPosition}) {
    final parsed = TagParser.parseTags(text);
    if (parsed.contains(tagName.toLowerCase())) {
      return text;
    }
    if (position == TagAppendPosition.front) {
      return '#$tagName ${text.trim()}'.trim();
    } else {
      return '${text.trim()} #$tagName'.trim();
    }
  }

  /// Removes a hashtag from the text, handling surrounding whitespace cleanly.
  static String removeTagFromText(String text, String tagName) {
    final escapedName = RegExp.escape(tagName);
    final regExp = RegExp('\\s*#$escapedName\\b', caseSensitive: false);
    var result = text.replaceAll(regExp, '');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Matches the current text hashtags to existing tag IDs.
  static List<String> syncTitleToPicker(String text, List<Tag> allTags) {
    final parsedNames = TagParser.parseTags(text);
    return allTags.where((t) => parsedNames.contains(t.name.toLowerCase())).map((t) => t.id).toList();
  }
}
