import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WindowTitleState composes title and subtitle stack', () {
    const base = WindowTitleState(
      baseTitle: 'Carpe',
      baseSubtitle: 'Project',
      subtitleStack: ['Task', 'Details'],
    );

    expect(base.title, 'Carpe');
    expect(base.subtitle, 'Project -> Task - Details');
    expect(base.fullTitle, 'Carpe - Project -> Task - Details');
    expect(base.copyWith(baseTitle: 'New').baseTitle, 'New');
    expect(base.copyWith(clearBaseSubtitle: true).subtitle, isNull);
    expect(
      const WindowTitleState(baseTitle: 'Only', subtitleStack: []).fullTitle,
      'Only',
    );
    expect(
      const WindowTitleState(
        baseTitle: 'Only',
        baseSubtitle: '',
        subtitleStack: [],
      ).fullTitle,
      'Only',
    );
  });

  test('notifier updates, stacks, pops, and resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(windowTitleProvider.notifier);

    expect(container.read(windowTitleProvider).baseTitle, AppConstants.appName);
    notifier.updateTitle(title: 'Projects', subtitle: 'One');
    notifier.pushSubtitle('Task');
    expect(
      container.read(windowTitleProvider).fullTitle,
      'Projects - One -> Task',
    );
    notifier.popSubtitle();
    expect(container.read(windowTitleProvider).fullTitle, 'Projects - One');
    notifier.popSubtitle();
    notifier.updateTitle(title: 'No subtitle');
    expect(container.read(windowTitleProvider).subtitle, isNull);
    notifier.reset();
    expect(container.read(windowTitleProvider).baseTitle, AppConstants.appName);
  });

  test('desktop window title failures are contained', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(windowTitleProvider.notifier).updateTitle(title: 'Desktop');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(windowTitleProvider).fullTitle, 'Desktop');
  });
}
