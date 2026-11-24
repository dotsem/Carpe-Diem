import 'package:carpe_diem/features/filter/presentation/providers/filter_accordion_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses defaults until an accordion is toggled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(filterAccordionProvider.notifier);

    expect(notifier.isExpanded('labels', true), isTrue);
    expect(notifier.isExpanded('projects', false), isFalse);

    notifier.toggle('labels', true);
    notifier.toggle('projects', false);

    expect(notifier.isExpanded('labels', true), isFalse);
    expect(notifier.isExpanded('projects', false), isTrue);
  });
}
