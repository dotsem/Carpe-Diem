import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';

@freezed
abstract class Project with _$Project implements Comparable<Project> {
  const Project._();
  const factory Project({
    required String id,
    required String name,
    required Color color,
    required DateTime createdAt,
    String? description,
    @Default(false) bool isUrgent,
    @Default([]) List<String> labelIds,
    DateTime? deadline,
    DateTime? updatedAt,
    @Default(true) bool isActive,
    @Default('') String sortOrder,
  }) = _Project;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color.toARGB32(),
    'isUrgent': isUrgent ? 1 : 0,
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActive': isActive ? 1 : 0,
    'sortOrder': sortOrder,
  };

  factory Project.fromMap(
    Map<String, dynamic> map, {
    List<String> labelIds = const [],
  }) => Project(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    color: Color(map['color'] as int),
    isUrgent: map['isUrgent'] == 1,
    labelIds: labelIds,
    deadline: map['deadline'] != null
        ? DateTime.parse(map['deadline'] as String)
        : null,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'] as String)
        : null,
    isActive: (map['isActive'] as int? ?? 1) == 1,
    sortOrder: map['sortOrder'] as String? ?? '',
  );

  @override
  int compareTo(Project other) {
    if (isUrgent && !other.isUrgent) return -1;
    if (!isUrgent && other.isUrgent) return 1;
    final sortComp = (sortOrder.isEmpty ? '~' : sortOrder).compareTo(
      other.sortOrder.isEmpty ? '~' : other.sortOrder,
    );
    if (sortComp != 0) return sortComp;
    return other.createdAt.compareTo(createdAt);
  }
}
