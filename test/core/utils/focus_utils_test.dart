import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('moves focus forward, backward, and reports focused id', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final nodes = {'one': first, 'two': second};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Focus(focusNode: first, child: const SizedBox()),
            Focus(focusNode: second, child: const SizedBox()),
          ],
        ),
      ),
    );

    FocusUtils.moveFocus(
      orderedItemIds: const ['one', 'two'],
      itemFocusNodes: nodes,
      delta: 1,
      debugLabelPrefix: 'item',
    );
    await tester.pump();
    expect(
      FocusUtils.getFocusedId(
        orderedItemIds: const ['one', 'two'],
        itemFocusNodes: nodes,
      ),
      'one',
    );

    FocusUtils.moveFocus(
      orderedItemIds: const ['one', 'two'],
      itemFocusNodes: nodes,
      delta: 1,
      debugLabelPrefix: 'item',
    );
    await tester.pump();
    expect(second.hasFocus, isTrue);

    FocusUtils.moveFocus(
      orderedItemIds: const ['one', 'two'],
      itemFocusNodes: nodes,
      delta: -5,
      debugLabelPrefix: 'item',
    );
    await tester.pump();
    expect(first.hasFocus, isTrue);
  });

  testWidgets('supports a special first node and lazily creates other nodes', (
    tester,
  ) async {
    final special = FocusNode();
    addTearDown(special.dispose);
    final nodes = <String, FocusNode>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Focus(focusNode: special, child: const SizedBox()),
      ),
    );

    FocusUtils.moveFocus(
      orderedItemIds: const ['one'],
      itemFocusNodes: nodes,
      delta: -1,
      debugLabelPrefix: 'item',
      firstItemFocusNode: special,
    );
    await tester.pump();

    expect(nodes['one'], same(special));
    expect(
      FocusUtils.getFocusedId(
        orderedItemIds: const ['one'],
        itemFocusNodes: nodes,
        firstItemFocusNode: special,
      ),
      'one',
    );
    expect(
      FocusUtils.getFocusedId(orderedItemIds: const [], itemFocusNodes: nodes),
      isNull,
    );
  });

  test('empty lists are no-ops and an unfocused list returns null', () {
    final nodes = <String, FocusNode>{};
    FocusUtils.moveFocus(
      orderedItemIds: const [],
      itemFocusNodes: nodes,
      delta: 1,
      debugLabelPrefix: 'item',
    );
    expect(nodes, isEmpty);
    expect(
      FocusUtils.getFocusedId(
        orderedItemIds: const ['missing'],
        itemFocusNodes: nodes,
      ),
      isNull,
    );
  });

  testWidgets('lazily creates ordinary first and next focus nodes', (
    tester,
  ) async {
    final nodes = <String, FocusNode>{};
    FocusUtils.moveFocus(
      orderedItemIds: const ['new'],
      itemFocusNodes: nodes,
      delta: 1,
      debugLabelPrefix: 'item',
    );
    expect(nodes['new']!.debugLabel, 'item_new');
    nodes['new']!.dispose();

    final first = FocusNode();
    addTearDown(first.dispose);
    final attached = <String, FocusNode>{'one': first};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Focus(focusNode: first, child: const SizedBox()),
      ),
    );
    first.requestFocus();
    await tester.pump();
    FocusUtils.moveFocus(
      orderedItemIds: const ['one', 'two'],
      itemFocusNodes: attached,
      delta: 1,
      debugLabelPrefix: 'item',
    );
    expect(attached['two']!.debugLabel, 'item_two');
    attached['two']!.dispose();
  });
}
