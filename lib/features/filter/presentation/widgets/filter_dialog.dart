import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/label_filter_picker.dart';

import 'package:carpe_diem/features/filter/presentation/widgets/project_filter_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

class FilterDialog extends ConsumerStatefulWidget {
  final TaskFilter initialFilter;
  final bool showProjectFilter;
  final bool showUrgencyFilter;
  final bool showLabelFilter;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    this.showProjectFilter = true,
    this.showUrgencyFilter = true,
    this.showLabelFilter = true,
  });

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  bool? _isUrgent;
  late Set<String> _projectIdsIncluded;
  late Set<String> _projectIdsExcluded;
  late Set<String> _labelIdsIncluded;
  late Set<String> _labelIdsExcluded;

  @override
  void initState() {
    super.initState();
    _isUrgent = widget.initialFilter.isUrgent;
    _projectIdsIncluded = Set.from(widget.initialFilter.projectIdsIncluded);
    _projectIdsExcluded = Set.from(widget.initialFilter.projectIdsExcluded);
    _labelIdsIncluded = Set.from(widget.initialFilter.labelIdsIncluded);
    _labelIdsExcluded = Set.from(widget.initialFilter.labelIdsExcluded);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final interactionMethod = settings.filterInteractionMethod;

    return SizedDialog(
      title: 'Filter Tasks',
      submitText: 'Apply',
      onCancel: () => Navigator.pop(context),
      onSubmit: () {
        final filter = widget.initialFilter.copyWith(
          isUrgent: _isUrgent,
          clearIsUrgent: _isUrgent == null,
          projectIdsIncluded: _projectIdsIncluded,
          projectIdsExcluded: _projectIdsExcluded,
          labelIdsIncluded: _labelIdsIncluded,
          labelIdsExcluded: _labelIdsExcluded,
        );
        Navigator.pop(context, filter);
      },
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _isUrgent = null;
              _projectIdsIncluded.clear();
              _projectIdsExcluded.clear();
              _labelIdsIncluded.clear();
              _labelIdsExcluded.clear();
            });
          },
          child: const Text('Clear All'),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showUrgencyFilter) ...[
              _sectionHeader('Urgency'),
              SegmentedButton<bool?>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment<bool?>(value: null, label: Text('Any')),
                  ButtonSegment<bool?>(value: true, label: Text('Urgent Only')),
                  ButtonSegment<bool?>(value: false, label: Text('Non-Urgent')),
                ],
                selected: {_isUrgent},
                onSelectionChanged: (Set<bool?> newSelection) {
                  setState(() {
                    _isUrgent = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            if (widget.showProjectFilter) ...[
              _sectionHeader('Project'),
              ProjectFilterPicker(
                included: _projectIdsIncluded,
                excluded: _projectIdsExcluded,
                onChanged: (inc, exc) => setState(() {
                  _projectIdsIncluded = inc;
                  _projectIdsExcluded = exc;
                }),
                interactionMethod: interactionMethod,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.showLabelFilter) ...[
              _sectionHeader('Labels'),
              LabelFilterPicker(
                selectedLabelIds: _labelIdsIncluded.toList(),
                excludedLabelIds: _labelIdsExcluded.toList(),
                onSelected: (inc) => setState(() => _labelIdsIncluded = Set.from(inc)),
                onExcluded: (exc) => setState(() => _labelIdsExcluded = Set.from(exc)),
                interactionMethod: interactionMethod,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
