import 'package:carpe_diem/features/filter/presentation/widgets/filter_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int filterTaps;
  late int bypassToggles;
  late int clears;

  Future<void> pump(WidgetTester tester, {bool isBypassed = false}) {
    filterTaps = 0;
    bypassToggles = 0;
    clears = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterButton(
            isBypassed: isBypassed,
            onFilterTap: () => filterTaps++,
            onToggleBypass: () => bypassToggles++,
            onClear: () => clears++,
          ),
        ),
      ),
    );
  }

  testWidgets('left click opens the filter dialog', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Filter'));
    expect((filterTaps, bypassToggles, clears), (1, 0, 0));
  });

  testWidgets('right click toggles bypass', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Filter'), buttons: kSecondaryButton);
    expect((filterTaps, bypassToggles, clears), (0, 1, 0));
  });

  testWidgets('right click still toggles while bypassed', (tester) async {
    await pump(tester, isBypassed: true);
    await tester.tap(find.text('Filter'), buttons: kSecondaryButton);
    expect(bypassToggles, 1);
  });

  testWidgets('middle click clears filters', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Filter'), buttons: kTertiaryButton);
    expect((filterTaps, bypassToggles, clears), (0, 0, 1));
  });
}
