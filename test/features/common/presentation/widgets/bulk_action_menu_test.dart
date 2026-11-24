import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bulk action menu selects enabled options and shows disabled ones',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionMenu(
              options: const [
                BulkActionOption(
                  value: 'edit',
                  icon: Icons.edit,
                  label: 'Edit',
                  enabled: true,
                ),
                BulkActionOption(
                  value: 'delete',
                  icon: Icons.delete,
                  label: 'Delete',
                  enabled: false,
                  isDestructive: true,
                ),
              ],
              onOptionSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(selected, 'edit');
    },
  );
}
