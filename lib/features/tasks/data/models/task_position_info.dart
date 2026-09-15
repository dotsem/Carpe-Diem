class TaskPositionInfo {
  final int indexInList;
  final int indexInGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isFirstInList;
  final bool isLastInList;

  const TaskPositionInfo({
    required this.indexInList,
    required this.indexInGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isFirstInList,
    required this.isLastInList,
  });

  const TaskPositionInfo.notFound()
    : indexInList = -1,
      indexInGroup = -1,
      isFirstInGroup = false,
      isLastInGroup = false,
      isFirstInList = false,
      isLastInList = false;
}
