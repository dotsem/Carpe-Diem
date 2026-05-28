enum TaskLayout {
  list,
  kanban;

  static TaskLayout fromString(String name) {
    return TaskLayout.values.firstWhere((e) => e.name == name);
  }
}
