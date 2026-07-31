import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:flutter/material.dart';

class ParentBreadcrumbChip extends StatelessWidget {
  final String parentTitle;

  const ParentBreadcrumbChip({super.key, required this.parentTitle});

  @override
  Widget build(BuildContext context) {
    final cleanTitle = TagParser.hideHashtagSymbols(parentTitle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              cleanTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
