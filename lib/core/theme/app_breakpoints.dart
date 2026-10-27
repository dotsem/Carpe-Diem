import 'package:flutter/widgets.dart';

/// Standard Tailwind-inspired responsive breakpoints.
enum AppBreakpoint implements Comparable<AppBreakpoint> {
  xs(360),
  sm(640),
  md(768),
  lg(1024),
  xl(1280),
  xxl(1536);

  final double minWidth;
  const AppBreakpoint(this.minWidth);

  static AppBreakpoint fromWidth(double width) {
    if (width >= xxl.minWidth) return AppBreakpoint.xxl;
    if (width >= xl.minWidth) return AppBreakpoint.xl;
    if (width >= lg.minWidth) return AppBreakpoint.lg;
    if (width >= md.minWidth) return AppBreakpoint.md;
    if (width >= sm.minWidth) return AppBreakpoint.sm;
    return AppBreakpoint.xs;
  }

  bool operator >=(AppBreakpoint other) => minWidth >= other.minWidth;
  bool operator <=(AppBreakpoint other) => minWidth <= other.minWidth;
  bool operator >(AppBreakpoint other) => minWidth > other.minWidth;
  bool operator <(AppBreakpoint other) => minWidth < other.minWidth;

  @override
  int compareTo(AppBreakpoint other) => minWidth.compareTo(other.minWidth);
}

/// Container-query extensions for [BoxConstraints] inside [LayoutBuilder].
extension ResponsiveBoxConstraints on BoxConstraints {
  AppBreakpoint get breakpoint => AppBreakpoint.fromWidth(maxWidth);

  bool isSmallerThan(AppBreakpoint target) => maxWidth < target.minWidth;
  bool isAtLeast(AppBreakpoint target) => maxWidth >= target.minWidth;
}

/// Screen-query extensions for [BuildContext].
extension ResponsiveContext on BuildContext {
  AppBreakpoint get screenBreakpoint =>
      AppBreakpoint.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isMobile => screenBreakpoint < AppBreakpoint.md;
  bool get isTablet =>
      screenBreakpoint >= AppBreakpoint.md &&
      screenBreakpoint < AppBreakpoint.lg;
  bool get isDesktop => screenBreakpoint >= AppBreakpoint.lg;

  bool isScreenSmallerThan(AppBreakpoint target) => screenBreakpoint < target;
  bool isScreenAtLeast(AppBreakpoint target) => screenBreakpoint >= target;
}
