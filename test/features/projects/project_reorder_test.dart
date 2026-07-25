import 'package:carpe_diem/core/utils/project_reorder_utils.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('project_reorder', () {
    final now = DateTime.now();
    final p1 = Project(
      id: '1',
      name: 'Project 1',
      color: Colors.blue,
      createdAt: now,
      sortOrder: 'a',
    );
    final p2 = Project(
      id: '2',
      name: 'Project 2',
      color: Colors.green,
      createdAt: now,
      sortOrder: 'b',
    );
    final p3 = Project(
      id: '3',
      name: 'Project 3',
      color: Colors.red,
      createdAt: now,
      sortOrder: 'c',
    );

    final projects = [p1, p2, p3];

    test('reorders project to beginning of list', () {
      final newSortOrder = ProjectReorderUtils.handleReorder(
        projects: projects,
        draggedProject: p3,
        newIndex: 0,
      );

      expect(newSortOrder, isNotNull);
      expect(newSortOrder!.compareTo(p1.sortOrder) < 0, isTrue);
    });

    test('reorders project to middle of list', () {
      final newSortOrder = ProjectReorderUtils.handleReorder(
        projects: projects,
        draggedProject: p1,
        newIndex: 1,
      );

      expect(newSortOrder, isNotNull);
      expect(newSortOrder!.compareTo(p2.sortOrder) > 0, isTrue);
      expect(newSortOrder.compareTo(p3.sortOrder) < 0, isTrue);
    });

    test('reorders project to end of list', () {
      final newSortOrder = ProjectReorderUtils.handleReorder(
        projects: projects,
        draggedProject: p1,
        newIndex: 2,
      );

      expect(newSortOrder, isNotNull);
      expect(newSortOrder!.compareTo(p3.sortOrder) > 0, isTrue);
    });

    test('no-op reorder returns null', () {
      final newSortOrder = ProjectReorderUtils.handleReorder(
        projects: projects,
        draggedProject: p2,
        newIndex: 1,
      );

      expect(newSortOrder, isNull);
    });

    test('computeSortOrderForSlot handles first, middle, and last slots', () {
      final remaining = [p2, p3];

      final firstRank = ProjectReorderUtils.computeSortOrderForSlot(
        draggedProject: p1,
        remainingProjects: remaining,
        slotIndex: 0,
      );
      expect(firstRank.compareTo(p2.sortOrder) < 0, isTrue);

      final middleRank = ProjectReorderUtils.computeSortOrderForSlot(
        draggedProject: p1,
        remainingProjects: remaining,
        slotIndex: 1,
      );
      expect(middleRank.compareTo(p2.sortOrder) > 0, isTrue);
      expect(middleRank.compareTo(p3.sortOrder) < 0, isTrue);

      final lastRank = ProjectReorderUtils.computeSortOrderForSlot(
        draggedProject: p1,
        remainingProjects: remaining,
        slotIndex: 2,
      );
      expect(lastRank.compareTo(p3.sortOrder) > 0, isTrue);
    });
  });
}
