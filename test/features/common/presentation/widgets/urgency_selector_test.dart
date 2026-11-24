import 'package:carpe_diem/features/common/presentation/widgets/urgency_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports urgent when Urgent is tapped', (tester) async {
    bool? urgency;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UrgencySelector(
            selected: null,
            allowAll: true,
            onChanged: (value) => urgency = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Urgent'));
    expect(urgency, isTrue);
  });
}
