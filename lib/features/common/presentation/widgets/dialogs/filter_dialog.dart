import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/multi_priority_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/multi_project_picker.dart';
import 'package:flutter/material.dart';

// TODO: refactor this code
class FilterDialog extends StatefulWidget {
  final TaskFilter initialFilter;
  final bool showProjectFilter;
  final bool showPriorityFilter;
  final bool showLabelFilter;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    this.showProjectFilter = true,
    this.showPriorityFilter = true,
    this.showLabelFilter = true,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<Priority> _priorities;
  late Set<String> _projectIds;
  late Set<String> _labelIds;

  @override
  void initState() {
    super.initState();
    _priorities = Set.from(widget.initialFilter.priorities);
    _projectIds = Set.from(widget.initialFilter.projectIds);
    _labelIds = Set.from(widget.initialFilter.labelIds);
  }

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'Filter Tasks',
      submitText: 'Apply',
      onCancel: () => Navigator.pop(context),
      onSubmit: () {
        final filter = widget.initialFilter.copyWith(
          priorities: _priorities,
          projectIds: _projectIds,
          labelIds: _labelIds,
        );
        Navigator.pop(context, filter);
      },
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _priorities.clear();
              _projectIds.clear();
              _labelIds.clear();
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
            if (widget.showPriorityFilter) ...[
              _sectionHeader('Priority'),
              MultiPriorityPicker(selected: _priorities, onChanged: (values) => setState(() => _priorities = values)),
              const SizedBox(height: 16),
            ],
            if (widget.showProjectFilter) ...[
              _sectionHeader('Project'),
              MultiProjectPicker(selected: _projectIds, onChanged: (values) => setState(() => _projectIds = values)),
              const SizedBox(height: 16),
            ],
            if (widget.showLabelFilter) ...[
              _sectionHeader('Labels'),
              LabelPicker(
                selectedLabelIds: _labelIds.toList(),
                onSelected: (values) => setState(() => _labelIds = Set.from(values)),
                allowAdd: false,
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
