enum TaskStatus {
  //! DB stores the indices, always append a new state
  todo,
  inProgress,
  done,
  review;

  bool get isTodo => this == TaskStatus.todo;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isDone => this == TaskStatus.done;
  bool get isReview => this == TaskStatus.review;
}
