import 'package:flutter/material.dart';


class Project {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final bool isUrgent;
  final List<String> labelIds;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final bool isActive;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    this.isUrgent = false,
    this.labelIds = const [],
    this.deadline,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color.toARGB32(),
    'isUrgent': isUrgent ? 1 : 0,
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive ? 1 : 0,
  };

  factory Project.fromMap(Map<String, dynamic> map, {List<String> labelIds = const []}) => Project(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    color: Color(map['color'] as int),
    isUrgent: map['isUrgent'] == 1,
    labelIds: labelIds,
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    isActive: (map['isActive'] as int? ?? 1) == 1,
  );

  Project copyWith({
    String? name,
    String? description,
    Color? color,
    bool? isUrgent,
    List<String>? labelIds,
    DateTime? deadline,
    bool? isActive,
  }) => Project(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    color: color ?? this.color,
    isUrgent: isUrgent ?? this.isUrgent,
    labelIds: labelIds ?? this.labelIds,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isActive: isActive ?? this.isActive,
  );
}
