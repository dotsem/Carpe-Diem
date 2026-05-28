import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';

const _presetColors = [
  AppColors.accent,
  Color(0xFFE53935),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF5E35B1),
  Color(0xFF3949AB),
  Color(0xFF1E88E5),
  Color(0xFF039BE5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF7CB342),
  Color(0xFFFFB300),
  Color(0xFFF4511E),
  Color(0xFF6D4C41),
  Color(0xFF78909C),
];

class ProjectColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const ProjectColorPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetColors.map((color) {
        final isSelected = color.toARGB32() == selected.toARGB32();
        final displayColor = color.themeDependentColor(context);

        return GestureDetector(
          onTap: () => onChanged(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5) : null,
            ),
            child: isSelected ? Icon(Icons.check, size: 16, color: displayColor.contrastColor) : null,
          ),
        );
      }).toList(),
    );
  }
}
