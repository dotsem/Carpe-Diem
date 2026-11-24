import 'dart:ui';

import 'package:carpe_diem/flutter_ext/dialogs/pick_date_range_dialog.dart';
import 'package:carpe_diem/flutter_ext/range_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget picker({required ValueChanged<DateTimeRange> onSelected}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: RangeDatePicker(
              initialStart: DateTime(2026, 1, 10),
              initialEnd: DateTime(2026, 1, 15),
              firstDate: DateTime(2026, 1, 5),
              lastDate: DateTime(2026, 2, 20),
              onRangeSelected: onSelected,
            ),
          ),
        ),
      );

  testWidgets('selects a range and normalizes reverse selection', (
    tester,
  ) async {
    DateTimeRange? selected;
    await tester.pumpWidget(picker(onSelected: (range) => selected = range));

    expect(find.text('January 2026'), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('8'));
    await tester.pump();

    expect(selected!.start, DateTime(2026, 1, 8));
    expect(selected!.end, DateTime(2026, 1, 20));
  });

  testWidgets('navigates within limits and disables out-of-range days', (
    tester,
  ) async {
    await tester.pumpWidget(picker(onSelected: (_) {}));
    final left = find.widgetWithIcon(IconButton, Icons.chevron_left);
    final right = find.widgetWithIcon(IconButton, Icons.chevron_right);
    expect(tester.widget<IconButton>(left).onPressed, isNull);

    await tester.tap(right);
    await tester.pump();
    expect(find.text('February 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(right).onPressed, isNull);
    await tester.tap(left);
    await tester.pump();
    expect(find.text('January 2026'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();
    expect(find.text('January 2026'), findsOneWidget);
  });

  testWidgets('hover previews a selecting range', (tester) async {
    await tester.pumpWidget(picker(onSelected: (_) {}));
    await tester.tap(find.text('10'));
    await tester.pump();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text('14')));
    await tester.pump();
    await gesture.moveTo(const Offset(399, 700));
    await tester.pump();
  });

  testWidgets('marks today when it is not a range endpoint', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: RangeDatePicker(
              initialStart: today.subtract(const Duration(days: 3)),
              initialEnd: today.subtract(const Duration(days: 2)),
              firstDate: DateTime(today.year, today.month),
              lastDate: DateTime(today.year, today.month + 1, 0),
              onRangeSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('${today.day}'), findsOneWidget);
  });

  testWidgets('dialog updates range and returns it on confirm', (tester) async {
    DateTimeRange? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<DateTimeRange>(
                context: context,
                builder: (_) => PickDateRangeDialog(
                  initialDateRange: DateTimeRange(
                    start: DateTime(2026, 1, 10),
                    end: DateTime(2026, 1, 15),
                  ),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('START'), findsOneWidget);
    expect(find.text('10/1/2026'), findsOneWidget);
    await tester.tap(find.text('12'));
    await tester.tap(find.text('18'));
    await tester.pump();
    expect(find.text('12/1/2026'), findsOneWidget);
    expect(find.text('18/1/2026'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(result?.start, DateTime(2026, 1, 12));
    expect(result?.end, DateTime(2026, 1, 18));
  });
}
