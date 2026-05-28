import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:flutter/material.dart';

class PriorityIndicator extends StatelessWidget {
  final Priority priority;

  const PriorityIndicator({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      decoration: BoxDecoration(color: priority.color, borderRadius: BorderRadius.circular(2)),
    );
  }
}
