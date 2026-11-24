import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/manageable_chip.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/tag_chip.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/widget_test_notifiers.dart';

void main() {
  testWidgets('label, tag, and manageable chips render and react', (
    tester,
  ) async {
    var taps = 0;
    // Why: const constructors only run when built non-const.
    final label = Label.empty().copyWith(
      id: 'l',
      name: 'Label',
      color: Colors.blue,
    );
    final tag = const Tag(id: 't', name: 'x').copyWith(name: 'Bug');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagIconProvider.overrideWith(TestTagIconNotifier.new)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LabelChip(label: label),
                TagChip(tag: tag),
                ManageableChip(
                  label: 'Manage',
                  avatar: const Icon(Icons.settings),
                  onTap: (_, _) => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Label'), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);
    await tester.tap(find.text('Manage'));
    await tester.tap(find.text('Manage'), buttons: kSecondaryMouseButton);
    await tester.pump();
    expect(taps, 2);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text('Manage')));
    await tester.pump();
    await gesture.moveTo(Offset.zero);
    await tester.pump();
  });
}
