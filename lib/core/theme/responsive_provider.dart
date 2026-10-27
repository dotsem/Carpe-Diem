import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_breakpoints.dart';

final screenBreakpointProvider =
    NotifierProvider<ScreenBreakpointNotifier, AppBreakpoint>(
      ScreenBreakpointNotifier.new,
    );

class ScreenBreakpointNotifier extends Notifier<AppBreakpoint>
    with WidgetsBindingObserver {
  @override
  AppBreakpoint build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return _computeBreakpoint();
  }

  @override
  void didChangeMetrics() {
    state = _computeBreakpoint();
  }

  AppBreakpoint _computeBreakpoint() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return AppBreakpoint.md;
    final physicalWidth = view.physicalSize.width;
    final devicePixelRatio = view.devicePixelRatio;
    final logicalWidth = devicePixelRatio > 0
        ? physicalWidth / devicePixelRatio
        : physicalWidth;
    return AppBreakpoint.fromWidth(logicalWidth);
  }
}
