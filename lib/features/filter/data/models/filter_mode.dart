import 'package:carpe_diem/core/constants/tag_icon_constants.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_mode.freezed.dart';

@freezed
abstract class FilterMode with _$FilterMode {
  const FilterMode._();
  const factory FilterMode({
    required String id,
    required String name,
    required TaskFilter filter,
    @Default(false) bool isDefault,
    int? iconCodePoint,
  }) = _FilterMode;

  IconData? get icon => iconCodePoint != null
      ? (availableIconMap[iconCodePoint] ?? Icons.tune)
      : null;

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
}
