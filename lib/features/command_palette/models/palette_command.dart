import 'package:flutter/widgets.dart';

enum CommandCategory {
  navigation('Navigation'),
  projects('Projects'),
  actions('Actions'),
  backlog('Backlog');

  final String label;
  const CommandCategory(this.label);
}

class PaletteCommand {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final CommandCategory category;
  final VoidCallback onSelect;
  final List<String> keywords;

  const PaletteCommand({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    required this.category,
    required this.onSelect,
    this.keywords = const [],
  });

  String get searchableText =>
      '$title ${subtitle ?? ''} ${keywords.join(' ')} ${category.label}';
}
