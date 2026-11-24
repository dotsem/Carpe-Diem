import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'project orders by urgency, sort order and age, and round-trips through maps',
    () {
      final date = DateTime(2026);
      final urgent = Project(
        id: 'urgent',
        name: 'Urgent',
        color: Colors.red,
        isUrgent: true,
        deadline: date,
        updatedAt: date,
        createdAt: date,
      );
      final normal = Project(
        id: 'normal',
        name: 'Normal',
        color: Colors.blue,
        createdAt: date.add(const Duration(days: 1)),
      );
      expect(urgent.compareTo(normal), -1);
      expect(normal.compareTo(urgent), 1);
      expect(Project.fromMap(urgent.toMap()).toMap(), urgent.toMap());
      expect(Project.fromMap(normal.toMap()).toMap(), normal.toMap());
      expect(
        normal
            .copyWith(sortOrder: 'a')
            .compareTo(normal.copyWith(sortOrder: 'b')),
        lessThan(0),
      );
      expect(normal.compareTo(normal.copyWith(createdAt: date)), lessThan(0));
    },
  );
}
