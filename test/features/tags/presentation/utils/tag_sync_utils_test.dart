import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';

void main() {
  group('tags', () {
    final mockTags = [
      const Tag(id: '1', name: 'work'),
      const Tag(id: '2', name: 'personal'),
      const Tag(id: '3', name: 'urgent'),
    ];

    group('syncTitleToPicker', () {
      test('should replace all selected tags when in replace mode and a tag is added', () {
        final result = TagSyncUtils.syncTitleToPicker(
          text: 'Do tasks #work',
          allTags: mockTags,
          currentSelectedIds: ['2', '3'],
          previousParsedIds: [],
          mode: Absorption.replace,
        );
        expect(result, equals(['1']));
      });

      test('should append tag when in append mode and a tag is added', () {
        final result = TagSyncUtils.syncTitleToPicker(
          text: 'Do tasks #work',
          allTags: mockTags,
          currentSelectedIds: ['2', '3'],
          previousParsedIds: [],
          mode: Absorption.append,
        );
        expect(result, containsAll(['1', '2', '3']));
        expect(result.length, equals(3));
      });

      test('should remove tag when tag is deleted from text', () {
        final result = TagSyncUtils.syncTitleToPicker(
          text: 'Do tasks',
          allTags: mockTags,
          currentSelectedIds: ['1', '2'],
          previousParsedIds: ['1'],
          mode: Absorption.replace,
        );
        expect(result, equals(['2']));
      });

      test('should not change anything if no tags are added or removed', () {
        final result = TagSyncUtils.syncTitleToPicker(
          text: 'Do tasks #work',
          allTags: mockTags,
          currentSelectedIds: ['1', '2'],
          previousParsedIds: ['1'],
          mode: Absorption.replace,
        );
        expect(result, equals(['1', '2']));
      });
    });
  });
}
