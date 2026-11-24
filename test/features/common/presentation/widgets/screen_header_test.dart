import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders string title, subtitle and actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScreenHeader(
            title: 'Title',
            subtitle: 'Subtitle',
            actions: [Icon(Icons.add)],
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('renders widget title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScreenHeader(
            title: Text('Widget title'),
            subtitle: Text('Widget subtitle'),
          ),
        ),
      ),
    );

    expect(find.text('Widget title'), findsOneWidget);
    expect(find.text('Widget subtitle'), findsOneWidget);
  });
}
