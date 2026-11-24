import 'package:carpe_diem/flutter_ext/hardware_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forwards key events only while enabled', (tester) async {
    final events = <KeyEvent>[];
    Widget build({required bool enabled}) => HardwareShortcuts(
      enabled: enabled,
      onKeyEvent: (event) {
        events.add(event);
        return true;
      },
      child: const SizedBox(),
    );

    await tester.pumpWidget(build(enabled: false));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(events, isEmpty);

    await tester.pumpWidget(build(enabled: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(events, isNotEmpty);

    events.clear();
    await tester.pumpWidget(build(enabled: false));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(events, isEmpty);
  });

  testWidgets('stops listening when removed from the tree', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      HardwareShortcuts(
        onKeyEvent: (_) {
          calls++;
          return true;
        },
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);

    expect(calls, 0);
  });
}
