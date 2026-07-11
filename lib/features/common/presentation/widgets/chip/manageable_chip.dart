import 'package:flutter/material.dart';

class ManageableChip extends StatefulWidget {
  final String label;
  final Widget? avatar;
  final void Function(TapDownDetails details, RenderBox box) onTap;

  const ManageableChip({
    super.key,
    required this.label,
    this.avatar,
    required this.onTap,
  });

  @override
  State<ManageableChip> createState() => _ManageableChipState();
}

class _ManageableChipState extends State<ManageableChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final baseColor = theme.colorScheme.surfaceContainerHigh;
        final hoverColor = theme.colorScheme.surfaceContainerHighest;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              widget.onTap(details, box);
            },
            onSecondaryTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              widget.onTap(details, box);
            },
            child: Chip(
              label: Text(widget.label),
              avatar: widget.avatar,
              backgroundColor: _isHovered ? hoverColor : baseColor,
              mouseCursor: SystemMouseCursors.click,
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}
