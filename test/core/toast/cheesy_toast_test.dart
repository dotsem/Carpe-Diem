import 'package:carpe_diem/core/toast/cheesy_toast.dart';
import 'package:carpe_diem/core/widgets/progress_border_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toastification/toastification.dart';

class MockToastificationItem extends Mock implements ToastificationItem {}

void main() {
  group('CheesyToast', () {
    late MockToastificationItem item;

    setUp(() {
      item = MockToastificationItem();
      when(() => item.hasTimer).thenReturn(true);
      when(() => item.originalDuration).thenReturn(const Duration(seconds: 3));
      when(() => item.elapsedDuration).thenReturn(Duration.zero);
      when(() => item.isStarted).thenReturn(true);
      when(() => item.timeStatus).thenReturn(ToastTimeStatus.started);
      when(() => item.addListenerOnTimeStatus(any())).thenReturn(null);
      when(() => item.removeListenerOnTimeStatus(any())).thenReturn(null);
    });

    testWidgets('pauses timer on hover enter and resumes on exit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CheesyToast(
                message: 'Test message',
                icon: Icons.check,
                color: Colors.green,
                item: item,
              ),
            ),
          ),
        ),
      );

      final customPaints = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final hasProgressBorder = customPaints.any(
        (cp) =>
            cp.foregroundPainter is ProgressBorderPainter &&
            !(cp.foregroundPainter as ProgressBorderPainter).left,
      );
      expect(hasProgressBorder, isTrue);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pump();
      verifyNever(() => item.pause());

      final toastCenter = tester.getCenter(
        find.descendant(
          of: find.byType(CheesyToast),
          matching: find.byType(ClipRRect),
        ),
      );
      await gesture.moveTo(toastCenter);
      await tester.pump();

      verify(() => item.pause()).called(1);
      verifyNever(() => item.start());

      await gesture.moveTo(const Offset(800, 800));
      await tester.pump();

      verify(() => item.start()).called(1);
    });

    testWidgets('renders with fixed width and right alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 200,
              child: CheesyToast(
                message: 'Short',
                icon: Icons.check,
                color: Colors.green,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
      );

      final alignFinder = find.descendant(
        of: find.byType(CheesyToast),
        matching: find.byType(Align),
      );
      final alignWidget = tester.widget<Align>(alignFinder);
      expect(alignWidget.alignment, equals(Alignment.centerRight));

      final sizedBoxFinder = find.descendant(
        of: alignFinder,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 380,
        ),
      );
      expect(sizedBoxFinder, findsOneWidget);

      final sizedBoxRect = tester.getRect(sizedBoxFinder);
      expect(sizedBoxRect.width, equals(380));
      // In 500px wide parent with 12px margin on both sides:
      // Available width is 476, right margin is at 488 (500 - 12).
      // Since SizedBox is right aligned, right edge should be at 488.
      expect(sizedBoxRect.right, equals(488));
    });
  });
}
