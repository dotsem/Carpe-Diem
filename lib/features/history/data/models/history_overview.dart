class HistoryOverview {
  final int totalCompleted;
  final int totalCreated;
  final int missedDeadlines;
  final int completedLate; // Completed after scheduled date
  final Map<String, int> tasksByProject; // ProjectId -> count
  final Map<String, int> tasksByLabel; // LabelId -> count

  HistoryOverview({
    required this.totalCompleted,
    required this.totalCreated,
    required this.missedDeadlines,
    required this.completedLate,
    required this.tasksByProject,
    required this.tasksByLabel,
  });

  factory HistoryOverview.empty() => HistoryOverview(
    totalCompleted: 0,
    totalCreated: 0,
    missedDeadlines: 0,
    completedLate: 0,
    tasksByProject: {},
    tasksByLabel: {},
  );
}

class ProjectHistorySummary {
  final String? projectId;
  final String projectName;
  final int taskCount;
  final int color;

  ProjectHistorySummary({
    required this.projectId,
    required this.projectName,
    required this.taskCount,
    required this.color,
  });
}
