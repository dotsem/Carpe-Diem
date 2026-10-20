import 'package:carpe_diem/core/widgets/progress_border_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressBorderPainter', () {
    test('shouldRepaint returns true when properties change', () {
      const painter1 = ProgressBorderPainter(
        progress: 0.5,
        color: Colors.blue,
        width: 2.5,
        borderRadius: 12.0,
      );
      const painterIdentical = ProgressBorderPainter(
        progress: 0.5,
        color: Colors.blue,
        width: 2.5,
        borderRadius: 12.0,
      );
      const painterDiffProgress = ProgressBorderPainter(
        progress: 0.6,
        color: Colors.blue,
        width: 2.5,
        borderRadius: 12.0,
      );
      const painterDiffColor = ProgressBorderPainter(
        progress: 0.5,
        color: Colors.red,
        width: 2.5,
        borderRadius: 12.0,
      );
      const painterDiffWidth = ProgressBorderPainter(
        progress: 0.5,
        color: Colors.blue,
        width: 3.0,
        borderRadius: 12.0,
      );
      const painterDiffSide = ProgressBorderPainter(
        progress: 0.5,
        color: Colors.blue,
        width: 2.5,
        borderRadius: 12.0,
        left: false,
      );

      expect(painter1.shouldRepaint(painterIdentical), isFalse);
      expect(painter1.shouldRepaint(painterDiffProgress), isTrue);
      expect(painter1.shouldRepaint(painterDiffColor), isTrue);
      expect(painter1.shouldRepaint(painterDiffWidth), isTrue);
      expect(painter1.shouldRepaint(painterDiffSide), isTrue);
    });

    testWidgets('paints path when progress > 0 for both closed and open path', (
      tester,
    ) async {
      await tester.pumpWidget(
        Column(
          children: [
            const CustomPaint(
              size: Size(200, 50),
              foregroundPainter: ProgressBorderPainter(
                progress: 0.75,
                color: Colors.green,
              ),
            ),
            const CustomPaint(
              size: Size(200, 50),
              foregroundPainter: ProgressBorderPainter(
                progress: 0.75,
                color: Colors.green,
                left: false,
              ),
            ),
            CustomPaint(
              size: const Size(200, 50),
              foregroundPainter: ProgressBorderPainter(
                progress: 0.75,
                color: Colors.green,
                pathBuilder: (size, r) => Path()..lineTo(size.width, 0),
              ),
            ),
          ],
        ),
      );

      expect(find.byType(CustomPaint), findsNWidgets(3));
    });
  });
}
