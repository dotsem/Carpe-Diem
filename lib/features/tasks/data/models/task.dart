
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? scheduledDate;
  final TaskStatus status;
  final String? projectId;
  final bool isUrgent;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? blockedById;
  final String sortOrder;
  final List<String> labelIds;
  final List<String> tagIds;

  bool get isCompleted => status.isDone;

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool scheduledOverdue = scheduledDate != null && scheduledDate!.isBefore(today);
    bool deadlineOverdue = deadline != null && deadline!.isBefore(today);

    if (scheduledOverdue && deadline != null && !deadline!.isBefore(today)) {
      return false;
    }

    return scheduledOverdue || deadlineOverdue;
  }

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.scheduledDate,
    this.status = TaskStatus.todo,
    this.projectId,
    this.isUrgent = false,
    this.deadline,
    required this.createdAt,
    this.completedAt,
    this.blockedById,
    this.sortOrder = '',
    this.labelIds = const [],
    this.tagIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'isCompleted': isCompleted ? 1 : 0,
    'status': status.index,
    'projectId': projectId,
    'isUrgent': isUrgent ? 1 : 0,
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'blockedById': blockedById,
    'sortOrder': sortOrder,
  };

  factory Task.fromMap(Map<String, dynamic> map, {List<String> labelIds = const [], List<String> tagIds = const []}) =>
      Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        scheduledDate: map['scheduledDate'] != null ? DateTime.parse(map['scheduledDate'] as String) : null,
        status: TaskStatus.values[map['status'] as int],
        projectId: map['projectId'] as String?,
        isUrgent: map['isUrgent'] == 1,
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
        blockedById: map['blockedById'] as String?,
        sortOrder: (map['sortOrder'] as String?) ?? '',
        labelIds: labelIds,
        tagIds: tagIds,
      );

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    TaskStatus? status,
    String? projectId,
    bool clearProjectId = false,
    bool? isUrgent,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? completedAt,
    String? blockedById,
    bool clearBlockedBy = false,
    String? sortOrder,
    List<String>? labelIds,
    List<String>? tagIds,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    scheduledDate: clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
    status: status ?? this.status,
    projectId: clearProjectId ? null : (projectId ?? this.projectId),
    isUrgent: isUrgent ?? this.isUrgent,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    createdAt: createdAt,
    completedAt: status == TaskStatus.done
        ? (completedAt ?? DateTime.now())
        : (status != null && !status.isDone ? null : this.completedAt),
    blockedById: clearBlockedBy ? null : (blockedById ?? this.blockedById),
    sortOrder: sortOrder ?? this.sortOrder,
    labelIds: labelIds ?? this.labelIds,
    tagIds: tagIds ?? this.tagIds,
  );
}
