import 'dart:ui';

import 'package:carpe_diem/features/common/presentation/widgets/swinging_drag_proxy.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_notifiers.dart';

class _AnimationsOffSettings extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState({'animations_enabled': 'false'});
}

class _FakeClock {
  DateTime _now = DateTime(2026);

  DateTime read() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeClock clock, {
  double width = 200,
  SettingsNotifier Function()? settings,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      settingsProvider.overrideWith(settings ?? TestSettingsNotifier.new),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SwingingDragProxy(
            width: width,
            clock: clock.read,
            child: SizedBox(width: width, height: 80),
          ),
        ),
      ),
    ),
  ),
);

double _angle(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(SwingingDragProxy),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getRotation()
    .storage[1];

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(300, 300));
  await gesture.down(const Offset(300, 300));
  return gesture;
}

Future<void> _swipe(TestGesture gesture, _FakeClock clock, double toX) async {
  await gesture.moveTo(const Offset(330, 300));
  clock.advance(const Duration(milliseconds: 5));
  await gesture.moveTo(Offset(toX, 300));
}

void main() {
  testWidgets('swings against the pointer direction and settles back', (
    tester,
  ) async {
    final clock = _FakeClock();
    await _pump(tester, clock);
    final gesture = await _mouse(tester);

    await _swipe(gesture, clock, 900);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_angle(tester), isNegative);

    clock.advance(const Duration(milliseconds: 60));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_angle(tester), 0);
  });

  testWidgets('stays still when animations are disabled', (tester) async {
    final clock = _FakeClock();
    await _pump(tester, clock, settings: _AnimationsOffSettings.new);
    final gesture = await _mouse(tester);

    await _swipe(gesture, clock, 900);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(_angle(tester), 0);
  });

  testWidgets('wider proxies swing less than narrow ones', (tester) async {
    Future<double> maxAngle(double width) async {
      final clock = _FakeClock();
      await _pump(tester, clock, width: width);
      final gesture = await _mouse(tester);
      await _swipe(gesture, clock, 900);
      var peak = 0.0;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = peak < _angle(tester).abs() ? _angle(tester).abs() : peak;
      }
      await gesture.removePointer();
      await tester.pumpWidget(const SizedBox());
      return peak;
    }

    final narrow = await maxAngle(200);
    final wide = await maxAngle(1200);

    expect(narrow, greaterThan(wide));
  });

  testWidgets('ignores pointer events after it is removed', (tester) async {
    final clock = _FakeClock();
    await _pump(tester, clock);
    final gesture = await _mouse(tester);
    await tester.pumpWidget(const SizedBox());

    await _swipe(gesture, clock, 900);

    expect(tester.takeException(), isNull);
  });
}
