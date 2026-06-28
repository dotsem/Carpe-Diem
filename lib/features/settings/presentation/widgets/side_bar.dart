import 'package:carpe_diem/features/common/presentation/widgets/navigation_item.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/section.dart';
import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  final Section? section;
  final ValueChanged<Section> onTabSelected;

  const SideBar({super.key, required this.section, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: Section.values.map((tab) {
        return NavigationItem(
          icon: tab.icon,
          label: tab.label,
          isSelected: section == tab,
          onTap: () => onTabSelected(tab),
        );
      }).toList(),
    );
  }
}
