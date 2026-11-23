import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';

@freezed
abstract class Task with _$Task {
  const Task._();
  const factory Task({
    required String id,
    required String title,
    required DateTime createdAt,
    String? description,
    DateTime? scheduledDate,
    @Default(TaskStatus.todo) TaskStatus status,
    String? projectId,
    @Default(false) bool isUrgent,
    DateTime? deadline,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? blockedById,
    String? parentId,
    @Default('') String sortOrder,
    String? planSortOrder,
    @Default([]) List<String> labelIds,
    @Default([]) List<String> tagIds,
    String? blockerTitle,
    TaskStatus? blockerStatus,
  }) = _Task;

  bool get isCompleted => status.isDone;
  bool get isBlocked =>
      !isCompleted &&
      blockedById != null &&
      blockerStatus != null &&
      !blockerStatus!.isDone;
  bool isBlockedBy(Task? blocker) =>
      !isCompleted &&
      blockedById != null &&
      blocker != null &&
      !blocker.isCompleted;

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledOverdue =
        scheduledDate != null && scheduledDate!.isBefore(today);
    final deadlineOverdue = deadline != null && deadline!.isBefore(today);
    if (scheduledOverdue && deadline != null && !deadline!.isBefore(today)) {
      return false;
    }
    return scheduledOverdue || deadlineOverdue;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledDate': scheduledDate?.normalize.toIso8601String(),
    'isCompleted': isCompleted ? 1 : 0,
    'status': status.index,
    'projectId': projectId,
    'isUrgent': isUrgent ? 1 : 0,
    'deadline': deadline?.normalize.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'blockedById': blockedById,
    'parentId': parentId,
    'sortOrder': sortOrder,
    'planSortOrder': planSortOrder,
  };

  factory Task.fromMap(
    Map<String, dynamic> map, {
    List<String> labelIds = const [],
    List<String> tagIds = const [],
  }) => Task(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    scheduledDate: map['scheduledDate'] != null
        ? DateTime.parse(map['scheduledDate'] as String)
        : null,
    status: TaskStatus.values[map['status'] as int],
    projectId: map['projectId'] as String?,
    isUrgent: map['isUrgent'] == 1,
    deadline: map['deadline'] != null
        ? DateTime.parse(map['deadline'] as String)
        : null,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'] as String)
        : null,
    completedAt: map['completedAt'] != null
        ? DateTime.parse(map['completedAt'] as String)
        : null,
    blockedById: map['blockedById'] as String?,
    parentId: map['parentId'] as String?,
    sortOrder: (map['sortOrder'] as String?) ?? '',
    planSortOrder: map['planSortOrder'] as String?,
    labelIds: labelIds,
    tagIds: tagIds,
    blockerTitle: map['blockerTitle'] as String?,
    blockerStatus: map['blockerStatus'] != null
        ? TaskStatus.values[map['blockerStatus'] as int]
        : null,
  );

  /// Changes status while preserving a completion timestamp for done → done.
  Task withStatus(TaskStatus nextStatus, {DateTime? at}) {
    if (status.isDone == nextStatus.isDone) return copyWith(status: nextStatus);
    return copyWith(
      status: nextStatus,
      completedAt: nextStatus.isDone ? (at ?? DateTime.now()) : null,
    );
  }
}
