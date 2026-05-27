import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleState {
  final String baseTitle;
  final String? baseSubtitle;
  final List<String> subtitleStack;

  const WindowTitleState({
    required this.baseTitle,
    this.baseSubtitle,
    required this.subtitleStack,
  });

  String get title => baseTitle;

  String? get subtitle => baseSubtitle != null
      ? subtitleStack.isNotEmpty
          ? "$baseSubtitle -> ${subtitleStack.join(" - ")}"
          : baseSubtitle
      : null;

  String get fullTitle {
    final sub = subtitle;
    if (sub == null || sub.isEmpty) {
      return baseTitle;
    }
    return '$baseTitle - $sub';
  }

  WindowTitleState copyWith({
    String? baseTitle,
    String? baseSubtitle,
    bool clearBaseSubtitle = false,
    List<String>? subtitleStack,
  }) {
    return WindowTitleState(
      baseTitle: baseTitle ?? this.baseTitle,
      baseSubtitle: clearBaseSubtitle ? null : (baseSubtitle ?? this.baseSubtitle),
      subtitleStack: subtitleStack ?? this.subtitleStack,
    );
  }
}

class WindowTitleNotifier extends Notifier<WindowTitleState> {
  @override
  WindowTitleState build() {
    return const WindowTitleState(
      baseTitle: AppConstants.appName,
      subtitleStack: [],
    );
  }

  void updateTitle({String? title, String? subtitle}) {
    state = state.copyWith(
      baseTitle: title,
      baseSubtitle: subtitle,
      clearBaseSubtitle: subtitle == null,
    );
    _applyToWindow();
  }

  void pushSubtitle(String subtitle) {
    final newStack = List<String>.from(state.subtitleStack)..add(subtitle);
    state = state.copyWith(subtitleStack: newStack);
    _applyToWindow();
  }

  void popSubtitle() {
    if (state.subtitleStack.isNotEmpty) {
      final newStack = List<String>.from(state.subtitleStack)..removeLast();
      state = state.copyWith(subtitleStack: newStack);
      _applyToWindow();
    }
  }

  void reset() {
    state = const WindowTitleState(
      baseTitle: AppConstants.appName,
      subtitleStack: [],
    );
    _applyToWindow();
  }

  Future<void> _applyToWindow() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await windowManager.setTitle(state.fullTitle);
      } catch (e) {
        debugPrint('Failed to set window title: $e');
      }
    }
  }
}

final windowTitleProvider = NotifierProvider<WindowTitleNotifier, WindowTitleState>(() {
  return WindowTitleNotifier();
});
