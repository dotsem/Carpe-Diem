import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String? Function()> _pump(
  WidgetTester tester, {
  String? initial = 'One',
  Widget? prefixIcon,
  bool borderless = true,
}) async {
  var selected = initial;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SearchableDropdown<String>(
            items: const ['One', 'Two', 'Three'],
            selectedItem: selected,
            nameGetter: (item) => item ?? 'None',
            // Why: prefixIcon is only used when there is no leadingBuilder.
            leadingBuilder: prefixIcon == null
                ? (_) => const Icon(Icons.label)
                : null,
            prefixIcon: prefixIcon,
            borderless: borderless,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
    ),
  );
  return () => selected;
}

void main() {
  testWidgets('selecting an item updates the value and offers None', (
    tester,
  ) async {
    final selected = await _pump(tester);

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(find.text('None'), findsOneWidget);
    await tester.tap(find.text('Two').last);
    await tester.pumpAndSettle();

    expect(selected(), 'Two');
  });

  testWidgets('search filters the items and Enter confirms the match', (
    tester,
  ) async {
    final selected = await _pump(tester);

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Thr');
    await tester.pump();
    expect(find.text('Two'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(selected(), 'Three');
  });

  testWidgets('says so when nothing matches and keeps the value', (
    tester,
  ) async {
    final selected = await _pump(tester);

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No items found'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(selected(), 'One');
  });

  testWidgets('hover and arrow keys move the highlight, Enter selects it', (
    tester,
  ) async {
    final selected = await _pump(tester);
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'T');
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);

    await mouse.moveTo(tester.getCenter(find.text('Two').last));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected(), 'Two');
  });

  testWidgets('renders the prefix icon while nothing is selected', (
    tester,
  ) async {
    await _pump(
      tester,
      initial: null,
      prefixIcon: const Icon(Icons.search),
      borderless: false,
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
