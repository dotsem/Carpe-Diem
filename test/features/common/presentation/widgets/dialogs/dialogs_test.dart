import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/destructive_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';

void main() {
  group('common', () {
    testWidgets('DeleteDialog renders text and triggers callback', (
      WidgetTester tester,
    ) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DeleteDialog(
                      title: 'Delete Item',
                      message: 'Are you sure?',
                      onConfirm: () => confirmed = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(confirmed, true);
      expect(find.text('Delete Item'), findsNothing);
    });

    testWidgets('DestructiveDialog cancel dismisses without confirm', (
      WidgetTester tester,
    ) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DestructiveDialog(
                      title: 'Destructive Action',
                      message: 'This is destructive',
                      destructiveText: 'Remove',
                      onConfirm: () => confirmed = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Destructive Action'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, false);
      expect(find.text('Destructive Action'), findsNothing);
    });

    testWidgets('SizedDialog submits on Ctrl+Enter', (
      WidgetTester tester,
    ) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => SizedDialog(
                      title: 'Test Dialog',
                      onSubmit: () => submitted = true,
                      child: const TextField(),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(submitted, true);
    });
  });
}
