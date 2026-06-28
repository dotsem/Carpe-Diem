import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/side_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Section? _selectedTab;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      if (_selectedTab == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const ScreenHeader(title: 'Settings'),
              Expanded(child: SideBar(section: null, onTabSelected: (tab) => setState(() => _selectedTab = tab))),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ScreenHeader(
                padding: const EdgeInsets.only(
                  left: 48, // TODO: better to place the hamburger menu somewhere else
                  top: 16,
                  bottom: 16,
                ),
                title: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedTab = null),
                    ),
                    const SizedBox(width: 8),
                    Text(_selectedTab!.label),
                  ],
                ),
                subtitle: 'Configure your ${_selectedTab!.label.toLowerCase()} settings',
              ),
              Expanded(child: SectionContent(section: _selectedTab!)),
            ],
          ),
        );
      }
    } else {
      final activeTab = _selectedTab ?? Section.appearance;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SideBar(section: activeTab, onTabSelected: (tab) => setState(() => _selectedTab = tab)),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 32),
              child: Column(
                children: [
                  ScreenHeader(
                    title: activeTab.label,
                    subtitle: 'Configure your ${activeTab.label.toLowerCase()} settings',
                  ),
                  Expanded(child: SectionContent(section: activeTab)),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}
