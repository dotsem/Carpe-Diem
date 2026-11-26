import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows label and actions, and clears the selection', (
    tester,
  ) async {
    var cleared = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BulkActionBar(
            label: '2 things selected',
            onClearSelection: () => cleared++,
            actions: const [Text('first'), Text('second')],
          ),
        ),
      ),
    );

    expect(find.text('2 things selected'), findsOneWidget);
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear selection'));
    expect(cleared, 1);
  });
}
