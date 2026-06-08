import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_picker.dart';

void main() {
  group('common', () {
    testWidgets('renders all choices and triggers onChanged', (WidgetTester tester) async {
      Priority? changedPriority;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriorityPicker(
              selected: Priority.low,
              onChanged: (p) => changedPriority = p,
            ),
          ),
        ),
      );

      for (final p in Priority.values) {
        expect(find.text(p.label), findsOneWidget);
      }

      await tester.tap(find.text(Priority.high.label));
      await tester.pumpAndSettle();

      expect(changedPriority, Priority.high);
    });
  });
}
