import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

void main() {
  group('filter', () {
    test('TaskFilter is empty by default and identifies constraints correctly', () {
      const filter = TaskFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.hasUrgencyFilter, isFalse);
      expect(filter.hasProjectFilter, isFalse);
      expect(filter.hasLabelFilter, isFalse);
      expect(filter.hasTagFilter, isFalse);

      const priorityIncFilter = TaskFilter(isUrgent: true);
      expect(priorityIncFilter.isEmpty, isFalse);
      expect(priorityIncFilter.hasUrgencyFilter, isTrue);

      const projectIncFilter = TaskFilter(projectIdsIncluded: {'p1'});
      expect(projectIncFilter.isEmpty, isFalse);
      expect(projectIncFilter.hasProjectFilter, isTrue);

      const projectExcFilter = TaskFilter(projectIdsExcluded: {'p1'});
      expect(projectExcFilter.isEmpty, isFalse);
      expect(projectExcFilter.hasProjectFilter, isTrue);

      const labelIncFilter = TaskFilter(labelIdsIncluded: {'l1'});
      expect(labelIncFilter.isEmpty, isFalse);
      expect(labelIncFilter.hasLabelFilter, isTrue);

      const labelExcFilter = TaskFilter(labelIdsExcluded: {'l1'});
      expect(labelExcFilter.isEmpty, isFalse);
      expect(labelExcFilter.hasLabelFilter, isTrue);

      const tagIncFilter = TaskFilter(tagIdsIncluded: {'t1'});
      expect(tagIncFilter.isEmpty, isFalse);
      expect(tagIncFilter.hasTagFilter, isTrue);

      const tagExcFilter = TaskFilter(tagIdsExcluded: {'t1'});
      expect(tagExcFilter.isEmpty, isFalse);
      expect(tagExcFilter.hasTagFilter, isTrue);
    });

    test('copyWith updates fields correctly or defaults to current values', () {
      const filter = TaskFilter(isUrgent: false);
      final copied = filter.copyWith(projectIdsIncluded: {'p1'}, tagIdsIncluded: {'t1'}, clearIsUrgent: true);

      expect(copied.isUrgent, isNull);
      expect(copied.projectIdsIncluded, {'p1'});
      expect(copied.tagIdsIncluded, {'t1'});
      expect(copied.labelIdsIncluded, isEmpty);
    });

    test('limitTo limits constraints appropriately', () {
      const filter = TaskFilter(
        isUrgent: true,
        projectIdsIncluded: {'p1'},
        labelIdsIncluded: {'l1'},
        tagIdsIncluded: {'t1'},
        projectIdsExcluded: {'p2'},
        labelIdsExcluded: {'l2'},
        tagIdsExcluded: {'t2'},
      );

      final limitPriorityOnly = filter.limitTo(projects: false, labels: false, tags: false);
      expect(limitPriorityOnly.isUrgent, true);
      expect(limitPriorityOnly.projectIdsIncluded, isEmpty);
      expect(limitPriorityOnly.projectIdsExcluded, isEmpty);
      expect(limitPriorityOnly.labelIdsIncluded, isEmpty);
      expect(limitPriorityOnly.labelIdsExcluded, isEmpty);
      expect(limitPriorityOnly.tagIdsIncluded, isEmpty);
      expect(limitPriorityOnly.tagIdsExcluded, isEmpty);
    });

    test('toMap and fromMap serialize tag filters correctly', () {
      const filter = TaskFilter(isUrgent: true, tagIdsIncluded: {'t1'}, tagIdsExcluded: {'t2'});
      final map = filter.toMap();
      final restored = TaskFilter.fromMap(map);

      expect(restored.isUrgent, isTrue);
      expect(restored.tagIdsIncluded, {'t1'});
      expect(restored.tagIdsExcluded, {'t2'});
    });

    test('FilterInteractionMethod fromString works correctly', () {
      expect(FilterInteractionMethod.fromString('cycle'), FilterInteractionMethod.cycle);
      expect(FilterInteractionMethod.fromString('leftRightClick'), FilterInteractionMethod.leftRightClick);
      expect(FilterInteractionMethod.fromString('invalid_method'), FilterInteractionMethod.cycle);
    });
  });
}
