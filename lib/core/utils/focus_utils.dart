import 'package:flutter/widgets.dart';

class FocusUtils {
  static const _directionThreshold = 20.0;
  static const _offAxisWeight = 5000.0;

  /// Picks the closest candidate in the requested direction from [from].
  static String? pickNeighbour(
    Offset from,
    Map<String, Offset> candidates,
    int dx,
    int dy,
  ) {
    String? bestId;
    var bestScore = double.infinity;

    for (final entry in candidates.entries) {
      final diff = entry.value - from;

      var inDirection = false;
      if (dx > 0) {
        inDirection = diff.dx > _directionThreshold;
      } else if (dx < 0) {
        inDirection = diff.dx < -_directionThreshold;
      } else if (dy > 0) {
        inDirection = diff.dy > _directionThreshold;
      } else if (dy < 0) {
        inDirection = diff.dy < -_directionThreshold;
      }

      if (inDirection) {
        var score = diff.distanceSquared;
        if (dx != 0) score += diff.dy.abs() * _offAxisWeight;
        if (dy != 0) score += diff.dx.abs() * _offAxisWeight;

        if (score < bestScore) {
          bestScore = score;
          bestId = entry.key;
        }
      }
    }

    return bestId;
  }

  static void moveFocus({
    required List<String> orderedItemIds,
    required Map<String, FocusNode> itemFocusNodes,
    required int delta,
    required String debugLabelPrefix,
    FocusNode? firstItemFocusNode,
  }) {
    if (orderedItemIds.isEmpty) return;

    var currentIndex = -1;
    for (var j = 0; j < orderedItemIds.length; j++) {
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
      final nextIndex = (currentIndex + delta).clamp(
        0,
        orderedItemIds.length - 1,
      );
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
    for (var i = 0; i < orderedItemIds.length; i++) {
      final node = (i == 0 && firstItemFocusNode != null)
          ? firstItemFocusNode
          : itemFocusNodes[orderedItemIds[i]];
      if (node?.hasFocus ?? false) return orderedItemIds[i];
    }
    return null;
  }
}
