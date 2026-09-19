import 'package:flutter/material.dart';

class CommandPaletteSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final VoidCallback onClear;

  const CommandPaletteSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Type a command or search...',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Clear',
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
