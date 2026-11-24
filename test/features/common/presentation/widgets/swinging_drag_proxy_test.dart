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

Future<void> _pump(
  WidgetTester tester, {
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

// Why: the proxy derives velocity from DateTime.now(), which fake time skips.
Future<void> _swipe(
  WidgetTester tester,
  TestGesture gesture,
  double toX,
) async {
  await gesture.moveTo(const Offset(330, 300));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await gesture.moveTo(Offset(toX, 300));
}

void main() {
  testWidgets('swings against the pointer direction and settles back', (
    tester,
  ) async {
    await _pump(tester);
    final gesture = await _mouse(tester);

    await _swipe(tester, gesture, 900);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_angle(tester), isNegative);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_angle(tester), 0);
  });

  testWidgets('stays still when animations are disabled', (tester) async {
    await _pump(tester, settings: _AnimationsOffSettings.new);
    final gesture = await _mouse(tester);

    await _swipe(tester, gesture, 900);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(_angle(tester), 0);
  });

  testWidgets('wider proxies swing less than narrow ones', (tester) async {
    Future<double> maxAngle(double width) async {
      await _pump(tester, width: width);
      final gesture = await _mouse(tester);
      await _swipe(tester, gesture, 900);
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
    await _pump(tester);
    final gesture = await _mouse(tester);
    await tester.pumpWidget(const SizedBox());

    await _swipe(tester, gesture, 900);

    expect(tester.takeException(), isNull);
  });
}
