import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleProvider extends ChangeNotifier {
  String _baseTitle = AppConstants.appName;
  String? _baseSubtitle;
  final List<String> _subtitleStack = [];

  String get title => _baseTitle;
  String? get subtitle => _baseSubtitle != null
      ? _subtitleStack.isNotEmpty
            ? "$_baseSubtitle -> ${_subtitleStack.join(" - ")}"
            : _baseSubtitle
      : null;

  void updateTitle({String? title, String? subtitle}) {
    if (title != null) _baseTitle = title;
    _baseSubtitle = subtitle;

    _applyToWindow();
    notifyListeners();
  }

  void pushSubtitle(String subtitle) {
    _subtitleStack.add(subtitle);
    _applyToWindow();
    notifyListeners();
  }

  void popSubtitle() {
    if (_subtitleStack.isNotEmpty) {
      _subtitleStack.removeLast();
      _applyToWindow();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  void reset() {
    _baseTitle = AppConstants.appName;
    _baseSubtitle = null;
    _subtitleStack.clear();
    _applyToWindow();
    notifyListeners();
  }

  String get fullTitle {
    if (subtitle == null || subtitle!.isEmpty) {
      return _baseTitle;
    }
    return '$_baseTitle - $subtitle';
  }

  Future<void> _applyToWindow() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await windowManager.setTitle(fullTitle);
      } catch (e) {
        debugPrint('Failed to set window title: $e');
      }
    }
  }
}
