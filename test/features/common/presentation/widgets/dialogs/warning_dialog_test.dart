import 'package:carpe_diem/features/common/presentation/widgets/dialogs/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runs onConfirm when the warning action is tapped', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => WarningDialog(
                  title: 'Warning',
                  message: 'Continue?',
                  warningText: 'Proceed',
                  onConfirm: () => confirmed = true,
                ),
              ),
              child: const Text('Warn'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Warn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Continue?'), findsNothing);
  });
}
