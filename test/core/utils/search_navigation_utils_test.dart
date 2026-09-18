import 'package:carpe_diem/core/utils/search_navigation_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchNavigationUtils', () {
    final orderedIds = ['item-1', 'item-2', 'item-3'];

    test('ignores non-keydown events', () {
      final event = const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );

      String? changedId;
      var selected = false;

      final result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: 'item-1',
        onHighlightChanged: (id) => changedId = id,
        onSelect: () => selected = true,
      );

      expect(result, KeyEventResult.ignored);
      expect(changedId, isNull);
      expect(selected, isFalse);
    });

    test('ignores typing and vim navigation keys (j, k, h, l)', () {
      for (final key in [
        LogicalKeyboardKey.keyJ,
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyA,
      ]) {
        final event = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyJ,
          logicalKey: key,
          timeStamp: Duration.zero,
        );

        String? changedId;
        final result = SearchNavigationUtils.handleSearchKeyEvent(
          event: event,
          orderedIds: orderedIds,
          currentHighlightId: 'item-1',
          onHighlightChanged: (id) => changedId = id,
          onSelect: () {},
        );

        expect(result, KeyEventResult.ignored);
        expect(changedId, isNull);
      }
    });

    test('arrowDown advances highlight and clamps at end', () {
      final event = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );

      String? changedId;
      var result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: 'item-1',
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );

      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-2');

      result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: 'item-3',
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );

      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-3');
    });

    test('arrowUp decrements highlight and clamps at start', () {
      final event = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );

      String? changedId;
      var result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: 'item-3',
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );

      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-2');

      result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: 'item-1',
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );

      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-1');
    });

    test('arrowDown from null highlight picks first item', () {
      final event = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );

      String? changedId;
      final result = SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: orderedIds,
        currentHighlightId: null,
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );

      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-1');
    });

    test('enter and numpadEnter trigger onSelect', () {
      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
      ]) {
        final event = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: key,
          timeStamp: Duration.zero,
        );

        var selected = false;
        final result = SearchNavigationUtils.handleSearchKeyEvent(
          event: event,
          orderedIds: orderedIds,
          currentHighlightId: 'item-1',
          onHighlightChanged: (_) {},
          onSelect: () => selected = true,
        );

        expect(result, KeyEventResult.handled);
        expect(selected, isTrue);
      }
    });

    test('horizontal arrows respect allowHorizontal flag', () {
      final rightEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      String? changedId;
      var result = SearchNavigationUtils.handleSearchKeyEvent(
        event: rightEvent,
        orderedIds: orderedIds,
        currentHighlightId: 'item-1',
        allowHorizontal: false,
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );
      expect(result, KeyEventResult.ignored);
      expect(changedId, isNull);

      result = SearchNavigationUtils.handleSearchKeyEvent(
        event: rightEvent,
        orderedIds: orderedIds,
        currentHighlightId: 'item-1',
        allowHorizontal: true,
        onHighlightChanged: (id) => changedId = id,
        onSelect: () {},
      );
      expect(result, KeyEventResult.handled);
      expect(changedId, 'item-2');
    });

    test('escape calls onEscape even if orderedIds is empty', () {
      final escapeEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );

      var escaped = false;
      var result = SearchNavigationUtils.handleSearchKeyEvent(
        event: escapeEvent,
        orderedIds: [],
        currentHighlightId: null,
        onHighlightChanged: (_) {},
        onSelect: () {},
        onEscape: () => escaped = true,
      );

      expect(result, KeyEventResult.handled);
      expect(escaped, isTrue);

      result = SearchNavigationUtils.handleSearchKeyEvent(
        event: escapeEvent,
        orderedIds: ['item-1'],
        currentHighlightId: 'item-1',
        onHighlightChanged: (_) {},
        onSelect: () {},
      );

      expect(result, KeyEventResult.ignored);
    });
  });
}
