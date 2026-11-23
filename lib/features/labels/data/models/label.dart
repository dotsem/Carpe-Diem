import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'label.freezed.dart';

@freezed
abstract class Label with _$Label {
  const Label._();
  const factory Label({
    required String id,
    required String name,
    required Color color,
  }) = _Label;
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
  };
  factory Label.fromMap(Map<String, dynamic> map) => Label(
    id: map['id'] as String,
    name: map['name'] as String,
    color: Color(map['color'] as int),
  );
  factory Label.empty() =>
      const Label(id: '', name: '', color: Colors.transparent);
  bool get isEmpty => id.isEmpty && name.isEmpty;
}
