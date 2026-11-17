typedef Completion = ({String? projectId, DateTime completedAt});
typedef LeadTimeRow = ({
  String? projectId,
  DateTime createdAt,
  DateTime completedAt,
  DateTime? firstScheduledAt,
});
typedef SlipRow = ({String id, String title, int moves});
typedef PlanDay = ({int scheduled, int done});

class ScheduleEvent {
  final DateTime at;
  final DateTime? from;
  final DateTime? to;

  const ScheduleEvent({required this.at, this.from, this.to});
}

class ScheduleTimeline {
  final DateTime? current;
  final DateTime? completedAt;
  final List<ScheduleEvent> events;

  const ScheduleTimeline({
    this.current,
    this.completedAt,
    this.events = const [],
  });
}

class LeadTimeStats {
  final double medianIncubationDays;
  final double medianExecutionDays;
  final int sample;
  final List<({String projectId, double days})> slowestProjects;

  const LeadTimeStats({
    required this.medianIncubationDays,
    required this.medianExecutionDays,
    required this.sample,
    required this.slowestProjects,
  });
}

class SlipStats {
  final double movesPerTask;
  final List<SlipRow> topTasks;

  const SlipStats({required this.movesPerTask, required this.topTasks});
}

class PlanAccuracy {
  final Map<DateTime, PlanDay> days;

  const PlanAccuracy(this.days);

  int get scheduled => days.values.fold(0, (a, d) => a + d.scheduled);
  int get done => days.values.fold(0, (a, d) => a + d.done);
}

class ProjectVelocity {
  final String projectId;
  final double usualPerWeek;
  final double recentPerWeek;
  final double delta;
  final bool isNew;
  final DateTime lastCompletedAt;

  const ProjectVelocity({
    required this.projectId,
    required this.usualPerWeek,
    required this.recentPerWeek,
    required this.delta,
    required this.isNew,
    required this.lastCompletedAt,
  });
}

class CompletionGap {
  final DateTime start;
  final DateTime end;
  final int days;

  const CompletionGap({
    required this.start,
    required this.end,
    required this.days,
  });
}

class HistoryInsights {
  final List<ProjectVelocity> velocity;
  final DateTime? trackingSince;
  final LeadTimeStats? leadTimes;
  final SlipStats? slips;
  final PlanAccuracy? planAccuracy;

  const HistoryInsights({
    required this.velocity,
    this.trackingSince,
    this.leadTimes,
    this.slips,
    this.planAccuracy,
  });
}

class ActivityData {
  final Map<DateTime, int> dailyCounts;
  final DateTime start;
  final DateTime end;

  const ActivityData({
    required this.dailyCounts,
    required this.start,
    required this.end,
  });
}
