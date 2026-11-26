import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _itemExtent = 40.0;

Future<ScrollController> _pumpList(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              controller: controller,
              itemExtent: _itemExtent,
              itemCount: 20,
              itemBuilder: (_, index) => Text('$index'),
            ),
          ),
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  group('ensureIndexVisible', () {
    testWidgets('scrolls to an item above the viewport', (tester) async {
      final controller = await _pumpList(tester);
      controller.jumpTo(200);

      ensureIndexVisible(controller, 1, _itemExtent);
      await tester.pumpAndSettle();

      expect(controller.offset, 40);
    });

    testWidgets('scrolls to an item below the viewport', (tester) async {
      final controller = await _pumpList(tester);

      ensureIndexVisible(controller, 5, _itemExtent);
      await tester.pumpAndSettle();

      expect(controller.offset, 140);
    });

    testWidgets('does not scroll when the item is already visible', (
      tester,
    ) async {
      final controller = await _pumpList(tester);
      controller.jumpTo(80);

      ensureIndexVisible(controller, 3, _itemExtent);
      await tester.pumpAndSettle();

      expect(controller.offset, 80);
    });
  });
}
