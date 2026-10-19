import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LexoRank', () {
    test('default rank when both bounds are null', () {
      expect(LexoRank.generateBetween(null, null), equals('a0'));
    });

    test('generateTop returns rank before first element', () {
      final top = LexoRank.generateTop('a0');
      expect(top.compareTo('a0'), lessThan(0));
    });

    test('generateBottom returns rank after last element', () {
      final bottom = LexoRank.generateBottom('a0');
      expect(bottom.compareTo('a0'), greaterThan(0));
    });

    test('generateBetween returns rank strictly between prev and next', () {
      final mid = LexoRank.generateBetween('a0', 'a5');
      expect(mid.compareTo('a0'), greaterThan(0));
      expect(mid.compareTo('a5'), lessThan(0));
    });

    test('handles adjacent integers by appending fractional digits', () {
      final mid = LexoRank.generateBetween('a0', 'a1');
      expect(mid.compareTo('a0'), greaterThan(0));
      expect(mid.compareTo('a1'), lessThan(0));
    });

    test('handles deep consecutive insertions at top without underflow', () {
      String current = 'a0';
      for (int i = 0; i < 100; i++) {
        final prev = LexoRank.generateTop(current);
        expect(
          prev.compareTo(current),
          lessThan(0),
          reason: 'Failed at iteration $i: $prev should be < $current',
        );
        current = prev;
      }
    });

    test('handles deep consecutive insertions at bottom without overflow', () {
      String current = 'a0';
      for (int i = 0; i < 100; i++) {
        final next = LexoRank.generateBottom(current);
        expect(
          next.compareTo(current),
          greaterThan(0),
          reason: 'Failed at iteration $i: $next should be > $current',
        );
        current = next;
      }
    });

    test('handles consecutive midpoint insertions between adjacent keys', () {
      String low = 'a0';
      const high = 'a1';
      for (int i = 0; i < 20; i++) {
        final mid = LexoRank.generateBetween(low, high);
        expect(mid.compareTo(low), greaterThan(0));
        expect(mid.compareTo(high), lessThan(0));
        low = mid;
      }
    });

    test('handles identical keys by appending fraction', () {
      final mid = LexoRank.generateBetween('a0', 'a0');
      expect(mid.compareTo('a0'), greaterThan(0));
    });

    test('falls back gracefully on unparseable rank keys', () {
      expect(LexoRank.generateBetween('invalid', null), equals('a0'));
      expect(LexoRank.generateBetween(null, 'invalid'), equals('a0'));
      expect(LexoRank.generateBetween('invalid', 'invalid2'), equals('a0'));
    });
  });
}
