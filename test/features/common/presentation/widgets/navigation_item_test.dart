import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/navigation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('common', () {
    testWidgets('renders icon, label, and optional shortcutHint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () {},
              shortcutHint: 'Ctrl+S',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Ctrl+S'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('applies active theme color and background when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final materialFinder = find.descendant(
        of: find.byType(NavigationItem),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);
      
      final material = tester.widget<Material>(materialFinder);
      expect(material.color, AppColors.accent.withValues(alpha: 0.15));

      final textFinder = find.text('Settings');
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, AppColors.accent);
    });

    testWidgets('applies transparent background and default color when unselected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final materialFinder = find.descendant(
        of: find.byType(NavigationItem),
        matching: find.byType(Material),
      );
      final material = tester.widget<Material>(materialFinder);
      expect(material.color, Colors.transparent);
    });

    testWidgets('respects custom iconColor and iconSize', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () {},
              iconColor: Colors.red,
              iconSize: 24,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.settings);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.red);
      expect(icon.size, 24);
    });
  });
}
