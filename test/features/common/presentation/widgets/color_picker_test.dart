import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('marks the selected color and reports a tapped one', (
    tester,
  ) async {
    Color? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectColorPicker(
            selected: AppColors.accent,
            onChanged: (value) => picked = value,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsWidgets);
    await tester.tap(find.byType(GestureDetector).first);
    expect(picked, isNotNull);
  });
}
