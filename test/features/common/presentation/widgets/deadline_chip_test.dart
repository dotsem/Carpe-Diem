import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 8);

  Future<Color?> chipColor(
    WidgetTester tester, {
    required DateTime deadline,
    bool isCompleted = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: DeadlineChip(
            deadline: deadline,
            today: today,
            isCompleted: isCompleted,
          ),
        ),
      ),
    );
    return tester.widget<SmallChip>(find.byType(SmallChip)).color;
  }

  testWidgets('overdue deadline is tinted red', (tester) async {
    final color = await chipColor(tester, deadline: DateTime(2026, 11, 7));
    expect(color, AppColors.error.withValues(alpha: 0.2));
  });

  testWidgets('deadline tomorrow is tinted orange', (tester) async {
    final color = await chipColor(tester, deadline: DateTime(2026, 11, 9));
    expect(color, AppColors.accent.withValues(alpha: 0.2));
  });

  testWidgets('deadline in 3 days is tinted yellow', (tester) async {
    final color = await chipColor(tester, deadline: DateTime(2026, 11, 11));
    expect(color, AppColors.warning.withValues(alpha: 0.2));
  });

  testWidgets('completed task keeps the neutral tint even when overdue', (
    tester,
  ) async {
    final color = await chipColor(
      tester,
      deadline: DateTime(2026, 11, 1),
      isCompleted: true,
    );
    expect(color, isNot(AppColors.error.withValues(alpha: 0.2)));
    expect(color?.a, closeTo(0.1, 0.01));
  });
}
