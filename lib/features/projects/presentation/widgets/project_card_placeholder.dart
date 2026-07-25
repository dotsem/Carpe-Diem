import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProjectCardPlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const ProjectCardPlaceholder({
    super.key,
    this.width = 240,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.accent.withValues(alpha: 0.8);
    final fillColor = AppColors.accent.withValues(alpha: 0.05);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add_circle_outline_rounded,
          size: 28,
          color: borderColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
