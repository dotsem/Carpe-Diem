import 'package:flutter/material.dart';

class ProjectDetailFab extends StatelessWidget {
  final bool isActive;
  final Color color;
  final VoidCallback onPressed;

  const ProjectDetailFab({
    super.key,
    required this.isActive,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: color,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
