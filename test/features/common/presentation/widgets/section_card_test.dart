import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SectionCard', () {
    testWidgets('renders SectionCard.single correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard.single(
              icon: Icons.star,
              title: 'Single Title',
              child: Text('Child Widget'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Single Title'), findsOneWidget);
      expect(find.text('Child Widget'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('renders multi-item SectionCard with dividers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionCard(
              items: [
                SectionItem(
                  icon: Icons.folder,
                  title: 'First Section',
                  child: Text('First Child'),
                ),
                SectionItem(
                  icon: Icons.tag,
                  title: 'Second Section',
                  child: Text('Second Child'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.text('First Section'), findsOneWidget);
      expect(find.text('First Child'), findsOneWidget);

      expect(find.byIcon(Icons.tag), findsOneWidget);
      expect(find.text('Second Section'), findsOneWidget);
      expect(find.text('Second Child'), findsOneWidget);

      // Verify divider appears between items (1 divider for 2 items)
      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
