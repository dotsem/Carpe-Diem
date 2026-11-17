import 'package:flutter/material.dart';

class ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;
  final double borderRadius;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool top;
  final bool right;
  final bool bottom;
  final bool left;
  final Path Function(Size size, double borderRadius)? pathBuilder;

  const ProgressBorderPainter({
    required this.progress,
    required this.color,
    this.width = 2.0,
    this.borderRadius = 12.0,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.left = true,
    this.pathBuilder,
  });

  Path _buildPath(Size size, double r) {
    if (pathBuilder != null) {
      return pathBuilder!(size, r);
    }

    final hw = width / 2;
    final effectiveR = (r - hw).clamp(0.0, double.infinity);

    if (top && right && bottom && left) {
      final rect = Rect.fromLTWH(
        hw,
        hw,
        size.width - width,
        size.height - width,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(effectiveR));
      return Path()..addRRect(rrect);
    }

    final enabled = [top, right, bottom, left];
    if (!enabled.any((e) => e)) return Path();

    final x0 = hw;
    final y0 = hw;
    final x1 = size.width - hw;
    final y1 = size.height - hw;

    final hasTR = top && right;
    final hasBR = right && bottom;
    final hasBL = bottom && left;
    final hasTL = left && top;

    final starts = [
      Offset(left ? (hasTL ? x0 + effectiveR : x0) : x0 + effectiveR, y0),
      Offset(x1, top ? (hasTR ? y0 + effectiveR : y0) : y0 + effectiveR),
      Offset(right ? (hasBR ? x1 - effectiveR : x1) : x1 - effectiveR, y1),
      Offset(x0, bottom ? (hasBL ? y1 - effectiveR : y1) : y1 - effectiveR),
    ];

    final ends = [
      Offset(right ? (hasTR ? x1 - effectiveR : x1) : x1 - effectiveR, y0),
      Offset(x1, bottom ? (hasBR ? y1 - effectiveR : y1) : y1 - effectiveR),
      Offset(left ? (hasBL ? x0 + effectiveR : x0) : x0 + effectiveR, y1),
      Offset(x0, top ? (hasTL ? y0 + effectiveR : y0) : y0 + effectiveR),
    ];

    final cornerArcs = [hasTR, hasBR, hasBL, hasTL];

    int startIndex = 0;
    for (int i = 0; i < 4; i++) {
      final prev = (i - 1 + 4) % 4;
      if (enabled[i] && !enabled[prev]) {
        startIndex = i;
        break;
      }
    }

    final path = Path();
    bool isFirst = true;

    for (int step = 0; step < 4; step++) {
      final i = (startIndex + step) % 4;
      if (!enabled[i]) break;

      if (isFirst) {
        path.moveTo(starts[i].dx, starts[i].dy);
        isFirst = false;
      }

      path.lineTo(ends[i].dx, ends[i].dy);

      final next = (i + 1) % 4;
      if (enabled[next] && cornerArcs[i]) {
        path.arcToPoint(starts[next], radius: Radius.circular(effectiveR));
      }
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = strokeCap
      ..strokeJoin = strokeJoin
      ..isAntiAlias = true;

    final clampedProgress = progress.clamp(0.0, 1.0);
    final path = _buildPath(size, borderRadius);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractPath = metric.extractPath(
      0.0,
      metric.length * clampedProgress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant ProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeCap != strokeCap ||
        oldDelegate.strokeJoin != strokeJoin ||
        oldDelegate.top != top ||
        oldDelegate.right != right ||
        oldDelegate.bottom != bottom ||
        oldDelegate.left != left ||
        oldDelegate.pathBuilder != pathBuilder;
  }
}
