import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';

void main() {
  group('LexoRankUtils', () {
    test('default rank when both bounds are null', () {
      expect(LexoRankUtils.generateBetween(null, null), equals('m'));
    });

    test('generateTop returns rank before first element', () {
      final top = LexoRankUtils.generateTop('m');
      expect(top.compareTo('m'), lessThan(0));
    });

    test('generateBottom returns rank after last element', () {
      final bottom = LexoRankUtils.generateBottom('m');
      expect(bottom.compareTo('m'), greaterThan(0));
    });

    test('generateBetween returns rank strictly between prev and next', () {
      final mid = LexoRankUtils.generateBetween('g', 'm');
      expect(mid.compareTo('g'), greaterThan(0));
      expect(mid.compareTo('m'), lessThan(0));
    });

    test('handles adjacent characters by increasing string length', () {
      final mid = LexoRankUtils.generateBetween('a', 'b');
      expect(mid.compareTo('a'), greaterThan(0));
      expect(mid.compareTo('b'), lessThan(0));
    });

    test('handles consecutive insertions at top', () {
      String current = 'm';
      for (int i = 0; i < 5; i++) {
        final prev = LexoRankUtils.generateTop(current);
        expect(prev.compareTo(current), lessThan(0));
        current = prev;
      }
    });

    test('handles consecutive insertions at bottom', () {
      String current = 'm';
      for (int i = 0; i < 5; i++) {
        final next = LexoRankUtils.generateBottom(current);
        expect(next.compareTo(current), greaterThan(0));
        current = next;
      }
    });
    test('computeReorderSortOrder calculates correct string when reordering', () {
      final list = ['a', 'c', 'e'];
      // Move 'e' (index 2) to top (index 0)
      final newRankTop = LexoRankUtils.computeReorderSortOrder(list, 2, 0, (s) => s);
      expect(newRankTop.compareTo('a'), lessThan(0));

      // Move 'a' (index 0) to bottom (index 3 in ReorderableListView callback)
      final newRankBottom = LexoRankUtils.computeReorderSortOrder(list, 0, 3, (s) => s);
      expect(newRankBottom.compareTo('e'), greaterThan(0));

      // Move 'a' (index 0) to between 'c' and 'e' (index 2)
      final newRankMiddle = LexoRankUtils.computeReorderSortOrder(list, 0, 2, (s) => s);
      expect(newRankMiddle.compareTo('c'), greaterThan(0));
      expect(newRankMiddle.compareTo('e'), lessThan(0));
    });
  });
}
