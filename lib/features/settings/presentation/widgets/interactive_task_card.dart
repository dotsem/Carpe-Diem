import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';

class InteractiveTaskCard extends StatefulWidget {
  final double initialWidth;
  final ValueChanged<double> onChanged;

  const InteractiveTaskCard({
    super.key,
    required this.initialWidth,
    required this.onChanged,
  });

  @override
  State<InteractiveTaskCard> createState() => _InteractiveTaskCardState();
}

class _InteractiveTaskCardState extends State<InteractiveTaskCard> {
  late double _currentWidth;

  @override
  void initState() {
    super.initState();
    _currentWidth = widget.initialWidth;
  }

  @override
  void didUpdateWidget(InteractiveTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWidth != widget.initialWidth) {
      _currentWidth = widget.initialWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectColor = Colors.deepPurple.themeDependentColor(context);

    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        setState(() {
          _currentWidth = (1.0 - (localX / box.size.width)).clamp(0.0, 1.0);
        });
      },
      onPanEnd: (_) {
        widget.onChanged(_currentWidth);
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
                projectColor.withValues(alpha: 0),
                projectColor.withValues(alpha: 0.4),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0.0,
                (1.0 - _currentWidth).clamp(0.0, 1.0),
                (1.0 - _currentWidth).clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Task Card',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Drag me horizontally to adjust width',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
