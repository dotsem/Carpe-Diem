import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';

class TaskDraft {
  final String title;
  final String? description;
  final DateTime? scheduledDate;
  final String? projectId;
  final bool isUrgent;
  final DateTime? deadline;
  final String? blockedById;
  final String? parentId;
  final TaskPlacement placement;
  final List<String> labelIds;
  final List<String> tagIds;

  const TaskDraft({
    required this.title,
    this.description,
    this.scheduledDate,
    this.projectId,
    this.isUrgent = false,
    this.deadline,
    this.blockedById,
    this.parentId,
    this.placement = TaskPlacement.bottom,
    this.labelIds = const [],
    this.tagIds = const [],
  });
}
