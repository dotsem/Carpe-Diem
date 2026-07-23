import 'package:flutter/widgets.dart';

class FocusUtils {
  static void moveFocus({
    required List<String> orderedItemIds,
    required Map<String, FocusNode> itemFocusNodes,
    required int delta,
    FocusNode? firstItemFocusNode,
    required String debugLabelPrefix,
  }) {
    if (orderedItemIds.isEmpty) return;

    int currentIndex = -1;
    for (int j = 0; j < orderedItemIds.length; j++) {
      final node = (j == 0 && firstItemFocusNode != null)
          ? firstItemFocusNode
          : itemFocusNodes[orderedItemIds[j]];
      if (node?.hasFocus ?? false) {
        currentIndex = j;
        break;
      }
    }

    if (currentIndex == -1) {
      final targetIndex = delta > 0 ? 0 : orderedItemIds.length - 1;
      final id = orderedItemIds[targetIndex];
      final node = itemFocusNodes.putIfAbsent(
        id,
        () => (targetIndex == 0 && firstItemFocusNode != null)
            ? firstItemFocusNode
            : FocusNode(debugLabel: '${debugLabelPrefix}_$id'),
      );
      node.requestFocus();
    } else {
      final nextIndex = (currentIndex + delta).clamp(0, orderedItemIds.length - 1);
      final id = orderedItemIds[nextIndex];
      final node = itemFocusNodes.putIfAbsent(
        id,
        () => (nextIndex == 0 && firstItemFocusNode != null)
            ? firstItemFocusNode
            : FocusNode(debugLabel: '${debugLabelPrefix}_$id'),
      );
      node.requestFocus();
    }
  }

  static String? getFocusedId({
    required List<String> orderedItemIds,
    required Map<String, FocusNode> itemFocusNodes,
    FocusNode? firstItemFocusNode,
  }) {
    if (orderedItemIds.isEmpty) return null;
    for (int i = 0; i < orderedItemIds.length; i++) {
      final node = (i == 0 && firstItemFocusNode != null) ? firstItemFocusNode : itemFocusNodes[orderedItemIds[i]];
      if (node?.hasFocus ?? false) return orderedItemIds[i];
    }
    return null;
  }
}
