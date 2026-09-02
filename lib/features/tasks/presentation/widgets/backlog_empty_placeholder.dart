import 'package:flutter/material.dart';

class BacklogEmptyPlaceholder extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback onClearFilter;

  const BacklogEmptyPlaceholder({
    super.key,
    required this.isFiltering,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    if (isFiltering) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_alt, size: 64, color: color),
            const SizedBox(height: 16),
            const Text('No items found'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('Remove Filters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            'No backlog tasks',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
