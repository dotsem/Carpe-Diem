import 'package:flutter/material.dart';

class UrgencySelector extends StatelessWidget {
  final bool? selected;
  final ValueChanged<bool?> onChanged;

  /// if true: (All/Urgent/Non-Urgent), else: (Urgent/Non-Urgent)
  final bool allowAll;

  const UrgencySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool?>(
      expandedInsets: EdgeInsets.zero,
      segments: [
        if (allowAll) const ButtonSegment(value: null, label: Text('All')),
        const ButtonSegment(value: false, label: Text('Non-Urgent')),
        const ButtonSegment(value: true, label: Text('Urgent')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
