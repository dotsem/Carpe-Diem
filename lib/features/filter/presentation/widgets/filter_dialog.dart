import 'package:carpe_diem/features/common/presentation/widgets/urgency_selector.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/common/filter_accordion_section.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/label_filter_picker.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/project_filter_picker.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/tag_filter_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

class FilterDialog extends ConsumerStatefulWidget {
  final TaskFilter initialFilter;
  final bool showProjectFilter;
  final bool showUrgencyFilter;
  final bool showLabelFilter;
  final bool showTagFilter;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    this.showProjectFilter = true,
    this.showUrgencyFilter = true,
    this.showLabelFilter = true,
    this.showTagFilter = true,
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
  late Set<String> _tagIdsIncluded;
  late Set<String> _tagIdsExcluded;

  @override
  void initState() {
    super.initState();
    _isUrgent = widget.initialFilter.isUrgent;
    _projectIdsIncluded = Set.from(widget.initialFilter.projectIdsIncluded);
    _projectIdsExcluded = Set.from(widget.initialFilter.projectIdsExcluded);
    _labelIdsIncluded = Set.from(widget.initialFilter.labelIdsIncluded);
    _labelIdsExcluded = Set.from(widget.initialFilter.labelIdsExcluded);
    _tagIdsIncluded = Set.from(widget.initialFilter.tagIdsIncluded);
    _tagIdsExcluded = Set.from(widget.initialFilter.tagIdsExcluded);
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
          tagIdsIncluded: _tagIdsIncluded,
          tagIdsExcluded: _tagIdsExcluded,
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
              _tagIdsIncluded.clear();
              _tagIdsExcluded.clear();
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
              FilterAccordionSection(
                title: 'Urgency',
                categoryKey: 'urgency',
                includedCount: _isUrgent == true ? 1 : 0,
                excludedCount: _isUrgent == false ? 1 : 0,
                child: UrgencySelector(
                  selected: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                  allowAll: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.showProjectFilter) ...[
              FilterAccordionSection(
                title: 'Project',
                categoryKey: 'project',
                includedCount: _projectIdsIncluded.length,
                excludedCount: _projectIdsExcluded.length,
                child: ProjectFilterPicker(
                  included: _projectIdsIncluded,
                  excluded: _projectIdsExcluded,
                  onChanged: (inc, exc) => setState(() {
                    _projectIdsIncluded = inc;
                    _projectIdsExcluded = exc;
                  }),
                  interactionMethod: interactionMethod,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.showLabelFilter) ...[
              FilterAccordionSection(
                title: 'Labels',
                categoryKey: 'labels',
                includedCount: _labelIdsIncluded.length,
                excludedCount: _labelIdsExcluded.length,
                child: LabelFilterPicker(
                  selectedLabelIds: _labelIdsIncluded.toList(),
                  excludedLabelIds: _labelIdsExcluded.toList(),
                  onSelected: (inc) =>
                      setState(() => _labelIdsIncluded = Set.from(inc)),
                  onExcluded: (exc) =>
                      setState(() => _labelIdsExcluded = Set.from(exc)),
                  interactionMethod: interactionMethod,
                ),
              ),
            ],
            if (widget.showTagFilter) ...[
              if (widget.showLabelFilter) const SizedBox(height: 16),
              FilterAccordionSection(
                title: 'Tags',
                categoryKey: 'tags',
                includedCount: _tagIdsIncluded.length,
                excludedCount: _tagIdsExcluded.length,
                child: TagFilterPicker(
                  selectedTagIds: _tagIdsIncluded.toList(),
                  excludedTagIds: _tagIdsExcluded.toList(),
                  onSelected: (inc) =>
                      setState(() => _tagIdsIncluded = Set.from(inc)),
                  onExcluded: (exc) =>
                      setState(() => _tagIdsExcluded = Set.from(exc)),
                  interactionMethod: interactionMethod,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
