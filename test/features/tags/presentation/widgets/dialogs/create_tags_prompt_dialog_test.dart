import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/create_tags_prompt_dialog.dart';

void main() {
  group('tags', () {
    testWidgets('CreateTagsPromptDialog displays tags and pops with selected result action', (tester) async {
      CreateTagsPromptResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<CreateTagsPromptResult>(
                      context: context,
                      builder: (context) => const CreateTagsPromptDialog(
                        newTagNames: ['todo', 'groceries'],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Tags?'), findsOneWidget);
      expect(find.text('#todo'), findsOneWidget);
      expect(find.text('#groceries'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, equals(CreateTagsPromptResult.cancel));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Without Tags'));
      await tester.pumpAndSettle();

      expect(result, equals(CreateTagsPromptResult.saveWithoutTags));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create & Saves'));
      await tester.pumpAndSettle();

      expect(result, equals(CreateTagsPromptResult.createAndSave));
    });
  });
}
