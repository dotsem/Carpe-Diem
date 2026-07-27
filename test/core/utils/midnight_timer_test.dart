import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/midnight_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MidnightTimer', () {
    test('start and dispose lifecycle', () {
      final timer = MidnightTimer();
      var called = false;

      timer.start(() {
        called = true;
      });

      expect(called, isFalse);
      timer.dispose();
    });

    testWidgets('timer fires when date rolls over at midnight', (tester) async {
      var currentTime = DateTime(2026, 7, 27, 23, 59, 50);
      final timer = MidnightTimer(clock: () => currentTime);
      var called = false;

      timer.start(() {
        called = true;
      });

      expect(called, isFalse);

      currentTime = currentTime.add(const Duration(seconds: 11));
      await tester.pump(const Duration(seconds: 11));

      expect(called, isTrue);
      timer.dispose();
    });

    test('didChangeAppLifecycleState triggers date check on resumed if day changed', () {
      var currentTime = DateTime(2026, 7, 27, 12, 0, 0);
      final timer = MidnightTimer(clock: () => currentTime);
      var called = false;

      timer.start(() {
        called = true;
      });

      // Same day resume -> no callback
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(called, isFalse);

      // Simulate device waking from sleep on the next day
      currentTime = DateTime(2026, 7, 28, 8, 0, 0);
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(called, isTrue);

      timer.dispose();
    });
  });
}
