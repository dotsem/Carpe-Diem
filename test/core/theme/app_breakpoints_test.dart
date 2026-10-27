import 'package:carpe_diem/core/theme/app_breakpoints.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoint', () {
    test('fromWidth maps widths to correct breakpoints', () {
      expect(AppBreakpoint.fromWidth(320), equals(AppBreakpoint.xs));
      expect(AppBreakpoint.fromWidth(360), equals(AppBreakpoint.xs));
      expect(AppBreakpoint.fromWidth(639), equals(AppBreakpoint.xs));
      expect(AppBreakpoint.fromWidth(640), equals(AppBreakpoint.sm));
      expect(AppBreakpoint.fromWidth(767), equals(AppBreakpoint.sm));
      expect(AppBreakpoint.fromWidth(768), equals(AppBreakpoint.md));
      expect(AppBreakpoint.fromWidth(1023), equals(AppBreakpoint.md));
      expect(AppBreakpoint.fromWidth(1024), equals(AppBreakpoint.lg));
      expect(AppBreakpoint.fromWidth(1279), equals(AppBreakpoint.lg));
      expect(AppBreakpoint.fromWidth(1280), equals(AppBreakpoint.xl));
      expect(AppBreakpoint.fromWidth(1535), equals(AppBreakpoint.xl));
      expect(AppBreakpoint.fromWidth(1536), equals(AppBreakpoint.xxl));
      expect(AppBreakpoint.fromWidth(2560), equals(AppBreakpoint.xxl));
    });

    test('comparison operators work correctly', () {
      expect(AppBreakpoint.xs < AppBreakpoint.sm, isTrue);
      expect(AppBreakpoint.sm < AppBreakpoint.md, isTrue);
      expect(AppBreakpoint.md < AppBreakpoint.lg, isTrue);
      expect(AppBreakpoint.lg < AppBreakpoint.xl, isTrue);
      expect(AppBreakpoint.xl < AppBreakpoint.xxl, isTrue);

      expect(AppBreakpoint.md >= AppBreakpoint.sm, isTrue);
      expect(AppBreakpoint.md >= AppBreakpoint.md, isTrue);
      expect(AppBreakpoint.md <= AppBreakpoint.md, isTrue);
      expect(AppBreakpoint.md <= AppBreakpoint.lg, isTrue);
    });

    test('ResponsiveBoxConstraints extensions work correctly', () {
      const constraintsSmall = BoxConstraints(maxWidth: 320);
      expect(constraintsSmall.breakpoint, equals(AppBreakpoint.xs));
      expect(constraintsSmall.isSmallerThan(AppBreakpoint.xs), isTrue);
      expect(constraintsSmall.isAtLeast(AppBreakpoint.xs), isFalse);

      const constraintsLarge = BoxConstraints(maxWidth: 1200);
      expect(constraintsLarge.breakpoint, equals(AppBreakpoint.lg));
      expect(constraintsLarge.isSmallerThan(AppBreakpoint.xs), isFalse);
      expect(constraintsLarge.isAtLeast(AppBreakpoint.md), isTrue);
    });
  });
}
