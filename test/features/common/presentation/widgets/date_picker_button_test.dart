import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clears the date with the close icon and picks a new one', (
    tester,
  ) async {
    DateTime? selected = DateTime(2026, 1, 10);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DatePickerButton(
              label: 'Pick date',
              date: selected,
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(selected, isNull);

    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selected?.day, 15);
  });
}
