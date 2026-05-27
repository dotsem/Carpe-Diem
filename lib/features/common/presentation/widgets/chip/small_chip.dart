import 'package:flutter/material.dart';

class SmallChip extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;
  const SmallChip({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(borderRadius)),
      child: child,
    );
  }
}
