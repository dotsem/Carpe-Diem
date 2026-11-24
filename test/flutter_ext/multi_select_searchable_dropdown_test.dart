import 'package:carpe_diem/flutter_ext/searchable_dropdown/multi_select_searchable_dropdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Fruit = ({String id, String name});

const _fruits = <_Fruit>[
  (id: 'a', name: 'Apple'),
  (id: 'z', name: 'Zebra'),
  (id: 'm', name: 'Mango'),
];

Future<List<String> Function()> _openDropdown(
  WidgetTester tester, {
  List<String> initial = const [],
  List<String> disabled = const [],
  VoidCallback? onAddNew,
}) async {
  var selected = initial;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: MultiSelectSearchableDropdown<_Fruit>(
            items: _fruits,
            selectedIds: selected,
            idGetter: (fruit) => fruit.id,
            nameGetter: (fruit) => fruit.name,
            disabledIds: disabled,
            leadingBuilder: (_) => const Icon(Icons.label),
            onAddNew: onAddNew,
            addNewLabel: 'Create',
            onChanged: (ids) => setState(() => selected = ids),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('+ Add'));
  await tester.pumpAndSettle();
  return () => selected;
}

void main() {
  testWidgets('filters items of any type by their display name', (
    tester,
  ) async {
    await _openDropdown(tester);

    await tester.enterText(find.byType(TextField), 'zebr');
    await tester.pump();

    expect(find.text('Zebra'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets(
    'arrow keys move the highlight, wrapping around, and Enter toggles it',
    (tester) async {
      final selected = await _openDropdown(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected(), ['m']);
    },
  );

  testWidgets('hovering an item highlights it for Enter', (tester) async {
    final selected = await _openDropdown(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);

    await mouse.moveTo(tester.getCenter(find.text('Mango')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected(), ['m']);
  });

  testWidgets('Ctrl+Enter is left for the surrounding dialog', (tester) async {
    final selected = await _openDropdown(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(selected(), isEmpty);
  });

  testWidgets('tapping an item toggles it on and off', (tester) async {
    final selected = await _openDropdown(tester, initial: ['a']);

    await tester.tap(find.text('Zebra'));
    await tester.pump();
    expect(selected(), ['a', 'z']);
    await tester.tap(find.text('Zebra'));
    await tester.pump();

    expect(selected(), ['a']);
  });

  testWidgets('disabled items cannot be selected', (tester) async {
    final selected = await _openDropdown(tester, disabled: ['m']);

    await tester.tap(find.text('Mango'));
    await tester.pump();

    expect(selected(), isEmpty);
  });

  testWidgets('says so when nothing matches the search', (tester) async {
    await _openDropdown(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('No items found'), findsOneWidget);
  });

  testWidgets('submitting the search toggles the first match', (tester) async {
    final selected = await _openDropdown(tester);

    await tester.enterText(find.byType(TextField), 'zeb');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(selected(), ['z']);
  });

  testWidgets('the add-new entry calls onAddNew', (tester) async {
    var added = false;
    await _openDropdown(tester, onAddNew: () => added = true);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(added, isTrue);
  });

  testWidgets('anchorBuilder replaces the default button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiSelectSearchableDropdown<String>(
            items: const ['one'],
            selectedIds: const [],
            idGetter: (item) => item,
            nameGetter: (item) => item,
            onChanged: (_) {},
            anchorBuilder: (context, controller) => TextButton(
              onPressed: controller.open,
              child: const Text('Custom anchor'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('+ Add'), findsNothing);
    await tester.tap(find.text('Custom anchor'));
    await tester.pumpAndSettle();

    expect(find.text('one'), findsOneWidget);
  });
}
