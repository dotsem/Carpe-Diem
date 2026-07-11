import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

void main() {
  group('tags', () {
    group('parseTags', () {
      test('should return empty list when text has no tags', () {
        expect(TagParser.parseTags('Buy some milk'), isEmpty);
      });

      test('should parse a single tag', () {
        expect(TagParser.parseTags('Buy milk #groceries'), equals(['groceries']));
      });

      test('should parse multiple tags and convert to lowercase', () {
        expect(
          TagParser.parseTags('Buy milk #groceries #Todo #work-stuff'),
          equals(['groceries', 'todo', 'work-stuff']),
        );
      });

      test('should ignore duplicate tags', () {
        expect(TagParser.parseTags('Task #todo #todo #TODO'), equals(['todo']));
      });

      test('should ignore single hash symbols without letters', () {
        expect(TagParser.parseTags('Task # #a'), equals(['a']));
      });
    });

    group('stripTags', () {
      test('should return original text trimmed when no tags present', () {
        expect(TagParser.stripTags('Buy milk  '), equals('Buy milk'));
      });

      test('should strip tags and normalize whitespace', () {
        expect(TagParser.stripTags('Buy milk #groceries and bread #todo  '), equals('Buy milk and bread'));
      });

      test('should handle stripping multiple contiguous tags', () {
        expect(TagParser.stripTags('Buy milk #groceries #todo'), equals('Buy milk'));
      });
    });

    group('getActiveQuery', () {
      test('should return null when selection index is out of bounds', () {
        expect(TagParser.getActiveQuery('hello', -1), isNull);
        expect(TagParser.getActiveQuery('hello', 6), isNull);
      });

      test('should return null when cursor is not touching a hashtag', () {
        expect(TagParser.getActiveQuery('hello world', 5), isNull);
      });

      test('should detect active hashtag query when cursor is at the end', () {
        const text = 'Buy milk #gro';
        final query = TagParser.getActiveQuery(text, text.length);
        expect(query, isNotNull);
        expect(query!.query, equals('gro'));
        expect(query.startIndex, equals(9));
        expect(query.endIndex, equals(13));
      });

      test('should detect active hashtag query when cursor is inside the tag word', () {
        const text = 'Buy milk #groceries now';
        // Cursor is right after "gro" (index 13)
        final query = TagParser.getActiveQuery(text, 13);
        expect(query, isNotNull);
        expect(query!.query, equals('groceries'));
        expect(query.startIndex, equals(9));
        expect(query.endIndex, equals(19));
      });

      test('should return query with empty string when cursor is directly after a single hash', () {
        const text = 'Buy milk #';
        final query = TagParser.getActiveQuery(text, text.length);
        expect(query, isNotNull);
        expect(query!.query, equals(''));
        expect(query.startIndex, equals(9));
        expect(query.endIndex, equals(10));
      });
    });
  });
}
