enum TaskStatus {
  todo,
  inProgress,
  done;

  bool get isTodo => this == TaskStatus.todo;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isDone => this == TaskStatus.done;
}
