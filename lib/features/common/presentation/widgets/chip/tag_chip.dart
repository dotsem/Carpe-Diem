import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';

IconData getTagIcon(String name) {
  final cleanName = name.trim().toLowerCase();
  switch (cleanName) {
    case 'bug':
    case 'issue':
      return Icons.bug_report;
    case 'feature':
    case 'feat':
    case 'new':
      return Icons.add_circle;
    case 'wip':
    case 'progress':
    case 'doing':
      return Icons.pending;
    case 'todo':
    case 'backlog':
      return Icons.playlist_add;
    case 'done':
    case 'complete':
    case 'resolved':
      return Icons.check_circle;
    case 'urgent':
    case 'priority':
    case 'hotfix':
      return Icons.whatshot;
    case 'personal':
    case 'self':
    case 'private':
      return Icons.person;
    case 'work':
    case 'office':
    case 'job':
      return Icons.business_center;
    case 'idea':
    case 'thought':
    case 'brainstorm':
      return Icons.lightbulb;
    case 'refactor':
    case 'clean':
    case 'chore':
      return Icons.build;
    case 'enhancement':
    case 'improve':
      return Icons.auto_awesome_motion;
    case 'optimize':
      return Icons.speed;
    case 'security':
      return Icons.security;
    case 'doc':
    case 'docs':
    case 'documentation':
      return Icons.description;
    case 'test':
    case 'tests':
    case 'testing':
      return Icons.flaky;
    default:
      return Icons.tag;
  }
}

class TagChip extends StatelessWidget {
  final Tag tag;
  final double verticalPadding;

  const TagChip({super.key, required this.tag, this.verticalPadding = 2});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayColor = colorScheme.onSurfaceVariant;
    final icon = getTagIcon(tag.name);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: TextStyle(color: displayColor, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
