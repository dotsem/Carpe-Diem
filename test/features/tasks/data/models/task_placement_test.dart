import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TaskPlacement exposes one flag per placement', () {
    for (final placement in TaskPlacement.values) {
      expect(placement.name, isNotEmpty);
    }
    expect(TaskPlacement.top.isTop, isTrue);
    expect(TaskPlacement.middle.isMiddle, isTrue);
    expect(TaskPlacement.bottom.isBottom, isTrue);
    expect(TaskPlacement.urgent.isUrgent, isTrue);
  });
}
