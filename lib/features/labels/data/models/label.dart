import 'package:flutter/material.dart';

class Label {
  final String id;
  final String name;
  final Color color;

  const Label({required this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color.toARGB32()};

  factory Label.fromMap(Map<String, dynamic> map) =>
      Label(id: map['id'] as String, name: map['name'] as String, color: Color(map['color'] as int));

  Label copyWith({String? name, Color? color}) => Label(id: id, name: name ?? this.name, color: color ?? this.color);
}
