import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/common/tri_state_filter_chip.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectFilterPicker extends ConsumerWidget {
  final Set<String> included;
  final Set<String> excluded;
  final void Function(Set<String> included, Set<String> excluded) onChanged;
  final FilterInteractionMethod interactionMethod;

  const ProjectFilterPicker({
    super.key,
    required this.included,
    required this.excluded,
    required this.onChanged,
    required this.interactionMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(projectProvider);
    if (provider.projects.isEmpty) {
      return Center(
        child: Text(
          'No projects available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.projects.where((p) => p.isActive).map((p) {
        final isIncluded = included.contains(p.id);
        final isExcluded = excluded.contains(p.id);

        void handleCycle() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isIncluded) {
            newInc.remove(p.id);
            newExc.add(p.id);
          } else if (isExcluded) {
            newExc.remove(p.id);
          } else {
            newInc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        void handleLeftClick() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isIncluded) {
            newInc.remove(p.id);
          } else {
            newExc.remove(p.id);
            newInc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        void handleRightClick() {
          final newInc = Set<String>.from(included);
          final newExc = Set<String>.from(excluded);
          if (isExcluded) {
            newExc.remove(p.id);
          } else {
            newInc.remove(p.id);
            newExc.add(p.id);
          }
          onChanged(newInc, newExc);
        }

        return TriStateFilterChip(
          label: p.name,
          isIncluded: isIncluded,
          isExcluded: isExcluded,
          color: p.color,
          interactionMethod: interactionMethod,
          onCycle: handleCycle,
          onLeftClick: handleLeftClick,
          onRightClick: handleRightClick,
        );
      }).toList(),
    );
  }
}
