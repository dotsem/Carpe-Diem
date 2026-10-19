class TaskReorderSlot {
  final int index;
  final bool isValid;
  final bool isUnchanged;

  const TaskReorderSlot({
    required this.index,
    required this.isValid,
    required this.isUnchanged,
  });

  const TaskReorderSlot.invalid()
    : index = -1,
      isValid = false,
      isUnchanged = true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskReorderSlot &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          isValid == other.isValid &&
          isUnchanged == other.isUnchanged;

  @override
  int get hashCode => Object.hash(index, isValid, isUnchanged);

  @override
  String toString() =>
      'TaskReorderSlot(index: $index, isValid: $isValid, isUnchanged: $isUnchanged)';
}
