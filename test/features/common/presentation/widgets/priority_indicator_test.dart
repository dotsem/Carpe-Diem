import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_indicator.dart';

void main() {
  group('common', () {
    testWidgets('renders Container with priority color', (WidgetTester tester) async {
      for (final priority in Priority.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriorityIndicator(priority: priority),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, priority.color);
      }
    });
  });
}
