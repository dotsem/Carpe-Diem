import 'package:flutter/material.dart';

class TaskProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;
  final double borderRadius;

  const TaskProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.width,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0.0, metrics.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant TaskProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
