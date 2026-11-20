import 'package:flutter/material.dart';

class TagHighlightingController extends TextEditingController {
  final List<String> Function() getExistingTagNames;

  TagHighlightingController({required this.getExistingTagNames, super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final regExp = RegExp(r'#([a-zA-Z0-9_\-]+)');
    final children = <TextSpan>[];
    var start = 0;

    final existingNames = getExistingTagNames()
        .map((n) => n.toLowerCase())
        .toSet();
    final primaryColor = Theme.of(context).colorScheme.primary;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        children.add(TextSpan(text: text.substring(start, match.start)));
      }

      final fullMatch = match.group(0)!;
      final tagName = match.group(1)!.toLowerCase();

      final tagColor = existingNames.contains(tagName)
          ? primaryColor
          : Colors.grey;

      children.add(
        TextSpan(
          text: fullMatch,
          style: TextStyle(color: tagColor, fontWeight: FontWeight.bold),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(style: style, children: children);
  }
}
