import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';

void main() {
  group('FuzzySearchUtils', () {
    final items = ['apple', 'apricot', 'banana', 'blueberry', 'orange'];

    test('should return all items when search query is empty', () {
      final results = FuzzySearchUtils.search(
        query: '',
        items: items,
        itemToString: (item) => item,
      );
      expect(results, equals(items));
    });

    test('should find exact matches and sort by match relevance', () {
      final results = FuzzySearchUtils.search(
        query: 'banana',
        items: items,
        itemToString: (item) => item,
      );
      expect(results.first, equals('banana'));
    });

    test('should find close fuzzy matches', () {
      final results = FuzzySearchUtils.search(
        query: 'aple',
        items: items,
        itemToString: (item) => item,
      );
      expect(results, contains('apple'));
    });

    test('should respect threshold and filter distant matches', () {
      final strictResults = FuzzySearchUtils.search(
        query: 'xyz',
        items: items,
        itemToString: (item) => item,
        threshold: 0.1,
      );
      expect(strictResults, isEmpty);
    });
  });
}
