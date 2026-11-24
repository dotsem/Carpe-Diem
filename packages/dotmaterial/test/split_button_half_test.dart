import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

BorderRadiusDirectional _radius(WidgetTester tester) {
  final button = tester.widget<ButtonStyleButton>(
    find.bySubtype<ButtonStyleButton>(),
  );
  final shape = button.style!.shape!.resolve({})! as RoundedRectangleBorder;
  return shape.borderRadius as BorderRadiusDirectional;
}

void main() {
  testWidgets('renders a plain button without icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplitButtonHalf(
          side: SplitSide.leading,
          onPressed: () {},
          child: const Text('Add'),
        ),
      ),
    );

    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('renders the icon when given', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplitButtonHalf(
          side: SplitSide.leading,
          onPressed: () {},
          icon: const Icon(Icons.add),
          child: const Text('Add'),
        ),
      ),
    );

    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('calls onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        SplitButtonHalf(
          side: SplitSide.trailing,
          onPressed: () => taps++,
          child: const Text('Add'),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    expect(taps, 1);
  });

  testWidgets('is disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitButtonHalf(
          side: SplitSide.leading,
          onPressed: null,
          child: Text('Add'),
        ),
      ),
    );

    final button = tester.widget<ButtonStyleButton>(
      find.bySubtype<ButtonStyleButton>(),
    );
    expect(button.enabled, isFalse);
  });

  testWidgets('leading half rounds its start corners', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplitButtonHalf(
          side: SplitSide.leading,
          onPressed: () {},
          child: const Text('Add'),
        ),
      ),
    );

    final radius = _radius(tester);
    expect(radius.topStart, const Radius.circular(16));
    expect(radius.topEnd, const Radius.circular(4));
  });

  testWidgets('trailing half rounds its end corners', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplitButtonHalf(
          side: SplitSide.trailing,
          onPressed: () {},
          child: const Text('Add'),
        ),
      ),
    );

    final radius = _radius(tester);
    expect(radius.topStart, const Radius.circular(4));
    expect(radius.topEnd, const Radius.circular(16));
  });
}
