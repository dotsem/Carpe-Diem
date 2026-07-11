import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class TagSyncUtils {
  /// Syncs title text changes to the selected tag IDs.
  /// If a new tag is detected in [text] (i.e., parsed tags has an ID not in [currentSelectedIds]):
  ///   - [TagSyncMode.replace]: replaces all selected tags with the newly parsed ones.
  ///   - [TagSyncMode.append]: appends the newly parsed tags to the current selections.
  /// If no new tag is added, but one was removed from [text] (compared to [previousParsedIds]),
  /// we remove that tag from [currentSelectedIds].
  static List<String> syncTitleToPicker({
    required String text,
    required List<Tag> allTags,
    required List<String> currentSelectedIds,
    required List<String> previousParsedIds,
    TagSyncMode mode = AppConstants.defaultTagSyncMode,
  }) {
    final parsedNames = TagParser.parseTags(text);
    final parsedTagIds = allTags
        .where((t) => parsedNames.contains(t.name.toLowerCase()))
        .map((t) => t.id)
        .toList();

    final addedIds = parsedTagIds.where((id) => !currentSelectedIds.contains(id)).toList();
    if (addedIds.isNotEmpty) {
      if (mode == TagSyncMode.replace) {
        return parsedTagIds;
      } else {
        return (Set<String>.from(currentSelectedIds)..addAll(parsedTagIds)).toList();
      }
    }

    final removedFromText = previousParsedIds.where((id) => !parsedTagIds.contains(id)).toList();
    if (removedFromText.isNotEmpty) {
      return currentSelectedIds.where((id) => !removedFromText.contains(id)).toList();
    }

    return currentSelectedIds;
  }
}
