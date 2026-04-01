import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BlockerIndicator extends StatelessWidget {
  final String blockerId;
  final String blockerTitle;
  final String blockedTaskId;

  const BlockerIndicator({super.key, required this.blockerId, required this.blockerTitle, required this.blockedTaskId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: 'Blocked by: $blockerTitle',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Task is blocked',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
