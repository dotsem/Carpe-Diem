import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the label with the given font size and padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShortcutHintBadge(
          label: 'Ctrl+K',
          fontSize: 14,
          padding: EdgeInsets.all(8),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Ctrl+K'));
    expect(text.style?.fontSize, 14);
    final box = tester.widget<Container>(find.byType(Container));
    expect(box.padding, const EdgeInsets.all(8));
  });

  testWidgets('uses 11pt text by default', (tester) async {
    final label = ['Esc'].first;
    await tester.pumpWidget(MaterialApp(home: ShortcutHintBadge(label: label)));

    expect(tester.widget<Text>(find.text('Esc')).style?.fontSize, 11);
  });
}
