import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows label and count, and hides the label in icon-only mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: TabBar(
            tabs: [
              HorizontalTab(
                label: 'Tasks',
                icon: Icon(Icons.task),
                count: 3,
                accentColor: Colors.red,
              ),
              HorizontalTab(
                label: 'Hidden',
                icon: Icon(Icons.history),
                showIconOnly: true,
              ),
              HorizontalTab(
                label: 'No accent',
                icon: Icon(Icons.circle),
                count: 1,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.text('No accent'), findsOneWidget);
  });
}
