import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TaskReorderSlot compares by value', () {
    const slot = TaskReorderSlot(index: 1, isValid: true, isUnchanged: false);
    const equal = TaskReorderSlot(index: 1, isValid: true, isUnchanged: false);
    expect(slot, equal);
    expect(slot.hashCode, equal.hashCode);
    expect(slot.toString(), contains('index: 1'));
    expect(slot, isNot(const TaskReorderSlot.invalid()));
  });
}
