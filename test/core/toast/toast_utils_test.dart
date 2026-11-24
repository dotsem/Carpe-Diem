import 'package:carpe_diem/core/toast/toast_utils.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('toast helpers render defaults, custom values, and undo', (
    tester,
  ) async {
    ToastUtils.showSuccess('No context yet');
    ToastUtils.showInfo('No context yet');
    ToastUtils.showWarning('No context yet');
    ToastUtils.showUndoable('No context yet', () {});
    late BuildContext context;
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      ),
    );

    ToastUtils.showSuccess('Saved', context: context, subtitle: 'Hidden');
    ToastUtils.showInfo(
      'Information',
      context: context,
      icon: Icons.lightbulb,
      iconColor: Colors.purple,
    );
    ToastUtils.showWarning('Warning', context: context);
    var undone = false;
    ToastUtils.showUndoable(
      'Deleted',
      () => undone = true,
      context: context,
      primaryColor: Colors.orange,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(undone, isFalse);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('toast helpers fall back to the root navigator context', (
    tester,
  ) async {
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );

    ToastUtils.showInfo('Root info');
    ToastUtils.showWarning('Root warning');
    ToastUtils.showUndoable('Root undo', () {}, iconColor: Colors.green);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });
}
