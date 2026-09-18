import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntityTimestampsInfo extends StatelessWidget {
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EntityTimestampsInfo({
    super.key,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final createdText = formatter.format(createdAt);
    final updatedText = updatedAt != null
        ? formatter.format(updatedAt!)
        : 'Never';
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = TextStyle(fontSize: 11, color: color);

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Created: $createdText', style: textStyle),
          const SizedBox(height: 4),
          Text('Updated: $updatedText', style: textStyle),
        ],
      ),
    );
  }
}
