import 'package:carpe_diem/features/history/presentation/providers/activity_provider.dart';
import 'package:carpe_diem/features/history/presentation/widgets/activity_heatmap.dart';
import 'package:carpe_diem/features/history/presentation/widgets/section_header.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitySection extends ConsumerStatefulWidget {
  const ActivitySection({super.key});

  @override
  ConsumerState<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends ConsumerState<ActivitySection> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final years = ref.watch(activityYearsProvider).value ?? const [];
    final data = ref.watch(activityProvider(_year)).value;
    final firstDayOfWeek = ref.watch(
      settingsProvider.select((s) => s.firstDayOfWeek),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('ACTIVITY'),
        if (years.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Last 12 months', null),
                  for (final year in years) _chip('$year', year),
                ],
              ),
            ),
          ),
        if (data != null)
          ActivityHeatmap(data: data, firstDayOfWeek: firstDayOfWeek),
      ],
    );
  }

  Widget _chip(String label, int? year) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _year == year,
      onSelected: (_) => setState(() => _year = year),
    ),
  );
}
