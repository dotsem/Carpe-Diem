import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';

void main() {
  group('tags', () {
    testWidgets('TagHighlightingController highlights existing tags in primary color and new tags in grey', (
      tester,
    ) async {
      late TextSpan textSpan;

      final controller = TagHighlightingController(
        text: 'Hello #work and #newtag',
        getExistingTagNames: () => ['work'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue)),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                textSpan = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                  style: const TextStyle(fontSize: 14),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, equals(4));

      // 'Hello '
      expect(textSpan.children![0].toPlainText(), equals('Hello '));
      expect(textSpan.children![0].style, isNull);

      // '#work' - existing tag
      expect(textSpan.children![1].toPlainText(), equals('#work'));
      expect(textSpan.children![1].style!.color, equals(Colors.blue));
      expect(textSpan.children![1].style!.fontWeight, equals(FontWeight.bold));

      // ' and '
      expect(textSpan.children![2].toPlainText(), equals(' and '));
      expect(textSpan.children![2].style, isNull);

      // '#newtag' - new tag (fallback grey color)
      expect(textSpan.children![3].toPlainText(), equals('#newtag'));
      expect(textSpan.children![3].style!.color, equals(Colors.grey));
      expect(textSpan.children![3].style!.fontWeight, equals(FontWeight.bold));
    });
  });
}
