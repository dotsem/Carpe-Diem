import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/tags/presentation/constants/tag_icon_constants.dart';
import 'package:flutter/material.dart';

class FilterMode {
  final String id;
  final String name;
  final TaskFilter filter;
  final bool isDefault;
  final int? iconCodePoint;

  const FilterMode({
    required this.id,
    required this.name,
    required this.filter,
    this.isDefault = false,
    this.iconCodePoint,
  });

  IconData? get icon => iconCodePoint != null
      ? (availableIconMap[iconCodePoint] ?? Icons.tune)
      : null;

  FilterMode copyWith({
    String? id,
    String? name,
    TaskFilter? filter,
    bool? isDefault,
    int? iconCodePoint,
  }) {
    return FilterMode(
      id: id ?? this.id,
      name: name ?? this.name,
      filter: filter ?? this.filter,
      isDefault: isDefault ?? this.isDefault,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filter': filter.toMap(),
      'isDefault': isDefault,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    };
  }

  factory FilterMode.fromMap(Map<String, dynamic> map) {
    return FilterMode(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      filter: map['filter'] != null
          ? TaskFilter.fromMap(map['filter'] as Map<String, dynamic>)
          : const TaskFilter(),
      isDefault: map['isDefault'] as bool? ?? false,
      iconCodePoint: map['iconCodePoint'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterMode &&
        other.id == id &&
        other.name == name &&
        other.filter == filter &&
        other.isDefault == isDefault &&
        other.iconCodePoint == iconCodePoint;
  }

  @override
  int get hashCode => Object.hash(id, name, filter, isDefault, iconCodePoint);
}
