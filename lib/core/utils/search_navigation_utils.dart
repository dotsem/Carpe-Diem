import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchNavigationUtils {
  static KeyEventResult handleSearchKeyEvent({
    required KeyEvent event,
    required List<String> orderedIds,
    required String? currentHighlightId,
    required ValueChanged<String> onHighlightChanged,
    required VoidCallback onSelect,
    VoidCallback? onEscape,
    Map<String, FocusNode>? itemFocusNodes,
    bool allowHorizontal = false,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (onEscape != null) {
        onEscape();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (orderedIds.isEmpty) {
      return KeyEventResult.ignored;
    }

    final isDown =
        key == LogicalKeyboardKey.arrowDown ||
        (allowHorizontal && key == LogicalKeyboardKey.arrowRight);
    final isUp =
        key == LogicalKeyboardKey.arrowUp ||
        (allowHorizontal && key == LogicalKeyboardKey.arrowLeft);
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    if (isDown) {
      final currentIndex = currentHighlightId == null
          ? -1
          : orderedIds.indexOf(currentHighlightId);
      final nextIndex = (currentIndex + 1).clamp(0, orderedIds.length - 1);
      final nextId = orderedIds[nextIndex];
      onHighlightChanged(nextId);
      _scrollToNode(nextId, itemFocusNodes);
      return KeyEventResult.handled;
    }

    if (isUp) {
      final currentIndex = currentHighlightId == null
          ? orderedIds.length
          : orderedIds.indexOf(currentHighlightId);
      final prevIndex = (currentIndex - 1).clamp(0, orderedIds.length - 1);
      final prevId = orderedIds[prevIndex];
      onHighlightChanged(prevId);
      _scrollToNode(prevId, itemFocusNodes);
      return KeyEventResult.handled;
    }

    if (isEnter) {
      onSelect();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  static void _scrollToNode(String id, Map<String, FocusNode>? nodes) {
    if (nodes == null) return;
    final node = nodes[id];
    final context = node?.context;
    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 150),
        alignment: 0.5,
      );
    }
  }
}
