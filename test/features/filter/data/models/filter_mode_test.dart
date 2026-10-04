import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filter_mode', () {
    test('serializes to and from map correctly', () {
      const mode = FilterMode(
        id: 'mode-1',
        name: 'Work',
        filter: TaskFilter(
          isUrgent: true,
          projectIdsIncluded: {'proj-1'},
          labelIdsIncluded: {'label-1'},
        ),
        isDefault: false,
      );

      final map = mode.toMap();
      final fromMap = FilterMode.fromMap(map);

      expect(fromMap, equals(mode));
      expect(fromMap.id, 'mode-1');
      expect(fromMap.name, 'Work');
      expect(fromMap.filter.isUrgent, isTrue);
      expect(fromMap.filter.projectIdsIncluded, {'proj-1'});
      expect(fromMap.filter.labelIdsIncluded, {'label-1'});
    });

    test('copyWith updates specified fields only', () {
      const mode = FilterMode(
        id: 'mode-1',
        name: 'School',
        filter: TaskFilter(tagIdsIncluded: {'tag-1'}),
      );

      final updated = mode.copyWith(name: 'College');
      expect(updated.name, 'College');
      expect(updated.id, 'mode-1');
      expect(updated.filter.tagIdsIncluded, {'tag-1'});
    });

    test('value equality checks match across all fields', () {
      const mode1 = FilterMode(
        id: '1',
        name: 'Personal',
        filter: TaskFilter(isUrgent: false),
      );
      const mode2 = FilterMode(
        id: '1',
        name: 'Personal',
        filter: TaskFilter(isUrgent: false),
      );
      const mode3 = FilterMode(
        id: '2',
        name: 'Personal',
        filter: TaskFilter(isUrgent: false),
      );

      expect(mode1, equals(mode2));
      expect(mode1.hashCode, equals(mode2.hashCode));
      expect(mode1, isNot(equals(mode3)));
    });

    test('supports iconCodePoint and derives icon correctly', () {
      const mode = FilterMode(
        id: '1',
        name: 'Study',
        filter: TaskFilter(),
        iconCodePoint: 0xe559,
      );

      final map = mode.toMap();
      expect(map['iconCodePoint'], 0xe559);

      final fromMap = FilterMode.fromMap(map);
      expect(fromMap.iconCodePoint, 0xe559);
      expect(fromMap.icon?.codePoint, 0xe559);

      final updated = mode.copyWith(iconCodePoint: 0xe123);
      expect(updated.iconCodePoint, 0xe123);
    });
  });
}
