import 'package:carpe_diem/features/common/presentation/widgets/context_menu_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tints the title and icon with the given color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContextMenuItemTile(
            leading: Icon(Icons.edit),
            title: 'Menu item',
            color: Colors.red,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Menu item')).style?.color,
      Colors.red,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.edit))).color,
      Colors.red,
    );
  });

  testWidgets('falls back to theme colors without a color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContextMenuItemTile(leading: Icon(Icons.edit), title: 'Plain'),
        ),
      ),
    );

    final context = tester.element(find.text('Plain'));
    expect(
      tester.widget<Text>(find.text('Plain')).style?.color,
      Theme.of(context).colorScheme.onSurface,
    );
  });
}
