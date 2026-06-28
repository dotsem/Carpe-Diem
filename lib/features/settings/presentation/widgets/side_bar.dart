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
        return SideBarItem(
          icon: tab.icon,
          label: tab.label,
          isSelected: section == tab,
          onTap: () => onTabSelected(tab),
        );
      }).toList(),
    );
  }
}

class SideBarItem extends StatelessWidget {
  const SideBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap, selected: isSelected);
  }
}
