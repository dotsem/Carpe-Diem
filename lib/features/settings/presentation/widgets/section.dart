import 'package:carpe_diem/features/settings/presentation/widgets/sections/appearance_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/data_management_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/defaults_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/filtering_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/labels_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/planning_section.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/tasks_section.dart';
import 'package:flutter/material.dart';

enum Section {
  appearance('Appearance', Icons.palette_outlined),
  labels('Labels', Icons.label_outline),
  planning('Planning', Icons.calendar_month_outlined),
  tasks('Tasks', Icons.task_alt),
  defaults('Defaults', Icons.settings_suggest_outlined),
  data('Data Management', Icons.analytics_outlined),
  filtering('Filtering', Icons.filter_alt_outlined);

  final String label;
  final IconData icon;
  const Section(this.label, this.icon);
}

class SectionContent extends StatelessWidget {
  final Section section;
  const SectionContent({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case Section.appearance:
        return const AppearanceSection();
      case Section.labels:
        return const LabelsSection();
      case Section.planning:
        return const PlanningSection();
      case Section.tasks:
        return const TasksSection();
      case Section.defaults:
        return const DefaultsSection();
      case Section.data:
        return const DataManagementSection();
      case Section.filtering:
        return const FilteringSection();
    }
  }
}
