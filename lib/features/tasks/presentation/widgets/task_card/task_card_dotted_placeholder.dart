import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskCardDottedPlaceholder extends ConsumerWidget {
  final Widget child;
  final double borderRadius;

  const TaskCardDottedPlaceholder({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isCompact = settings.compactMode;
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;

    return CustomPaint(
      painter: _DottedBorderPainter(
        color: outlineColor,
        radius: Radius.circular(borderRadius),
        strokeWidth: 1.5,
        dashLength: 5.0,
        dashGap: 4.0,
        padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      ),
      child: Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: child,
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final Radius radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final EdgeInsets padding;

  const _DottedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      padding.left + strokeWidth / 2,
      padding.top + strokeWidth / 2,
      (size.width - padding.horizontal - strokeWidth).clamp(
        0.0,
        double.infinity,
      ),
      (size.height - padding.vertical - strokeWidth).clamp(
        0.0,
        double.infinity,
      ),
    );

    final rrect = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(rrect);

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashLength + dashGap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.padding != padding;
  }
}
