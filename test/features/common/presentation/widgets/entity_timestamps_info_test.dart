import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/common/presentation/widgets/entity_timestamps_info.dart';

void main() {
  group('EntityTimestampsInfo', () {
    testWidgets('renders created and updated timestamps formatted', (
      tester,
    ) async {
      final createdAt = DateTime(2026, 9, 18, 14, 30);
      final updatedAt = DateTime(2026, 9, 18, 21, 24);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTimestampsInfo(
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          ),
        ),
      );

      expect(find.text('Created: Sep 18, 2026 14:30'), findsOneWidget);
      expect(find.text('Updated: Sep 18, 2026 21:24'), findsOneWidget);
    });

    testWidgets('renders "Never" when updatedAt is null', (tester) async {
      final createdAt = DateTime(2026, 9, 18, 14, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTimestampsInfo(createdAt: createdAt, updatedAt: null),
          ),
        ),
      );

      expect(find.text('Created: Sep 18, 2026 14:30'), findsOneWidget);
      expect(find.text('Updated: Never'), findsOneWidget);
    });
  });
}
