import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:flutter/material.dart';

class TestTaskNotifier extends TaskNotifier {
  final TaskState initial;
  TestTaskNotifier(this.initial);

  @override
  TaskState build() => initial;
}

class TestTagIconNotifier extends TagIconNotifier {
  @override
  Map<String, IconData> build() => const {'bug': Icons.bug_report};
}

class TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState({'show_review_state': 'true'});
}
