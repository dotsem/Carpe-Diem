import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';

class LabelChip extends StatelessWidget {
  final Label label;
  final double verticalPadding;

  const LabelChip({super.key, required this.label, this.verticalPadding = 2});

  @override
  Widget build(BuildContext context) {
    final displayColor = label.color.themeDependentColor(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: displayColor.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: displayColor.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: displayColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.name,
            style: TextStyle(color: displayColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
