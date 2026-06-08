import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_markdown_parser.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

void main() {
  group('tasks', () {
    test('should parse unchecked markdown checkboxes as TODO tasks', () {
      const markdown = '- [ ] Buy groceries\n- [ ] Clean the house';
      final tasks = TaskMarkdownParser.parseMarkdown(markdown);

      expect(tasks.length, equals(2));
      expect(tasks[0].title, equals('Buy groceries'));
      expect(tasks[0].status, equals(TaskStatus.todo));
      expect(tasks[1].title, equals('Clean the house'));
      expect(tasks[1].status, equals(TaskStatus.todo));
    });

    test('should parse checked markdown checkboxes as DONE tasks', () {
      const markdown = '- [x] Read a book\n- [x] Exercise';
      final tasks = TaskMarkdownParser.parseMarkdown(markdown);

      expect(tasks.length, equals(2));
      expect(tasks[0].title, equals('Read a book'));
      expect(tasks[0].status, equals(TaskStatus.done));
      expect(tasks[1].title, equals('Exercise'));
      expect(tasks[1].status, equals(TaskStatus.done));
    });

    test('should parse plain bullet points as TODO tasks', () {
      const markdown = '- Buy milk\n- Write code';
      final tasks = TaskMarkdownParser.parseMarkdown(markdown);

      expect(tasks.length, equals(2));
      expect(tasks[0].title, equals('Buy milk'));
      expect(tasks[0].status, equals(TaskStatus.todo));
      expect(tasks[1].title, equals('Write code'));
      expect(tasks[1].status, equals(TaskStatus.todo));
    });

    test('should ignore empty lines and non-list items', () {
      const markdown = 'Some header\n\n- [ ] Real task\nSome footer';
      final tasks = TaskMarkdownParser.parseMarkdown(markdown);

      expect(tasks.length, equals(1));
      expect(tasks[0].title, equals('Real task'));
      expect(tasks[0].status, equals(TaskStatus.todo));
    });

    test('should ignore empty or whitespace-only list items', () {
      const markdown = '- \n- [ ]\n- [ ] \n- [x]   \n- Valid task';
      final tasks = TaskMarkdownParser.parseMarkdown(markdown);

      expect(tasks.length, equals(1));
      expect(tasks[0].title, equals('Valid task'));
    });
  });
}
