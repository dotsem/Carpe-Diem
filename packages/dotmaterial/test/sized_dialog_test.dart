import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openDialog(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showDialog<void>(context: context, builder: (_) => dialog),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('falls back to closing the dialog when no onSubmit is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  SizedDialog(onCancel: () {}, child: const Text('Body')),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsNothing);
  });

  testWidgets('Cancel closes the dialog when only onSubmit is given', (
    tester,
  ) async {
    await _openDialog(
      tester,
      SizedDialog(onSubmit: () {}, child: const Text('Body')),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsNothing);
  });

  group('submit shortcut', () {
    late int submits;

    setUp(() => submits = 0);

    Future<void> open(WidgetTester tester) => _openDialog(
      tester,
      SizedDialog(onSubmit: () => submits++, child: const Text('Body')),
    );

    testWidgets('Ctrl+Enter and Ctrl+NumpadEnter submit', (tester) async {
      await open(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(submits, 2);
    });

    testWidgets('Meta+Enter submits', (tester) async {
      await open(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      expect(submits, 1);
    });

    testWidgets('Enter without a modifier and Ctrl+other keys do not', (
      tester,
    ) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(submits, 0);
    });
  });
}
