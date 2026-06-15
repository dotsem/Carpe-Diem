import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class SettingsState {
  final Map<String, String> _map;

  const SettingsState(this._map);

  String _get(String key, String defaultValue) => _map[key] ?? defaultValue;

  // Task Layout
  TaskLayout getTaskLayout() {
    final layoutStr = _get('task_layout', TaskLayout.list.name);
    try {
      return TaskLayout.fromString(layoutStr);
    } catch (_) {
      return TaskLayout.list;
    }
  }

  // Max Planning Days
  int get maxPlanningDays =>
      int.tryParse(_get(AppConstants.keyMaxPlanningDays, AppConstants.maxPlanningDaysAhead.toString())) ??
      AppConstants.maxPlanningDaysAhead;

  // First Day of Week
  int get firstDayOfWeek =>
      int.tryParse(_get(AppConstants.keyFirstDayOfWeek, AppConstants.firstDayOfWeek.toString())) ??
      AppConstants.firstDayOfWeek;

  // Task Completion Delay
  int get taskCompletionDelay =>
      int.tryParse(_get(AppConstants.keyTaskDelay, AppConstants.taskCompletionDelaySeconds.toString())) ??
      AppConstants.taskCompletionDelaySeconds;

  // Inherit Parent Deadline
  bool get inheritParentDeadline =>
      _get(AppConstants.keyInheritParentDeadline, AppConstants.inheritParentDeadline.toString()) == 'true';

  // Prioritize Deadlines
  bool get prioritizeDeadlines =>
      _get(AppConstants.keyPrioritizeDeadlines, AppConstants.prioritizeDeadlines.toString()) == 'true';

  // Prioritize Overdue
  bool get prioritizeOverdue =>
      _get(AppConstants.keyPrioritizeOverdue, AppConstants.prioritizeOverdue.toString()) == 'true';

  // Inherit Project Deadline
  bool get inheritProjectDeadline =>
      _get(AppConstants.keyInheritProjectDeadline, AppConstants.inheritProjectDeadline.toString()) == 'true';

  // Theme Mode
  ThemeMode get themeMode {
    final modeStr = _get(AppConstants.keyThemeMode, ThemeMode.system.name);
    return ThemeMode.values.firstWhere((e) => e.name == modeStr, orElse: () => ThemeMode.system);
  }

  // Task Gradient Width
  double get taskGradientWidth =>
      double.tryParse(_get(AppConstants.keyTaskGradientWidth, AppConstants.defaultTaskGradientWidth.toString())) ??
      AppConstants.defaultTaskGradientWidth;

  // Compact Mode
  bool get compactMode => _get(AppConstants.keyCompactMode, AppConstants.defaultCompactMode.toString()) == 'true';

  // Show Description on Card
  bool get showDescriptionOnCard =>
      _get(AppConstants.keyShowDescriptionOnCard, AppConstants.defaultShowDescriptionOnCard.toString()) == 'true';

  // Default Priority
  String get defaultPriority => _get(AppConstants.keyDefaultPriority, AppConstants.defaultTaskPriority);

  // Default Project
  String? get defaultProjectId {
    final id = _get(AppConstants.keyDefaultProjectId, 'null');
    return id == 'null' ? null : id;
  }

  // History Retention
  int get historyRetention =>
      int.tryParse(_get(AppConstants.keyHistoryRetention, AppConstants.defaultHistoryRetention.toString())) ??
      AppConstants.defaultHistoryRetention;

  // Default Stats Period
  String get defaultStatsPeriod => _get(AppConstants.keyDefaultStatsPeriod, AppConstants.defaultStatsPeriod);

  // Show Active Projects Only
  bool get showActiveProjectsOnly =>
      _get(AppConstants.keyShowActiveProjectsOnly, AppConstants.defaultShowActiveProjectsOnly.toString()) == 'true';

  // Enable Random Task Picker
  bool get enableRandomTask =>
      _get(AppConstants.keyEnableRandomTask, AppConstants.defaultEnableRandomTask.toString()) == 'true';

  // Filter Interaction Method
  FilterInteractionMethod get filterInteractionMethod {
    final methodStr = _get(AppConstants.keyFilterInteractionMethod, AppConstants.defaultFilterInteractionMethod);
    return FilterInteractionMethod.fromString(methodStr);
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final ISettingsRepository _repo;

  @override
  SettingsState build() {
    _repo = ref.watch(settingsRepositoryProvider);
    return const SettingsState({});
  }

  Future<void> loadSettings() async {
    final map = await _repo.getAll();
    state = SettingsState(map);
  }

  Future<void> _set(String key, String value) async {
    final updatedMap = Map<String, String>.from(state._map);
    updatedMap[key] = value;
    state = SettingsState(updatedMap);
    await _repo.set(key, value);
  }

  Future<void> setTaskLayout(TaskLayout layout) => _set('task_layout', layout.name);
  Future<void> setMaxPlanningDays(int days) => _set(AppConstants.keyMaxPlanningDays, days.toString());
  Future<void> setFirstDayOfWeek(int day) => _set(AppConstants.keyFirstDayOfWeek, day.toString());
  Future<void> setTaskCompletionDelay(int seconds) => _set(AppConstants.keyTaskDelay, seconds.toString());
  Future<void> setInheritParentDeadline(bool value) => _set(AppConstants.keyInheritParentDeadline, value.toString());
  Future<void> setPrioritizeDeadlines(bool value) => _set(AppConstants.keyPrioritizeDeadlines, value.toString());
  Future<void> setPrioritizeOverdue(bool value) => _set(AppConstants.keyPrioritizeOverdue, value.toString());
  Future<void> setInheritProjectDeadline(bool value) => _set(AppConstants.keyInheritProjectDeadline, value.toString());
  Future<void> setThemeMode(ThemeMode mode) => _set(AppConstants.keyThemeMode, mode.name);
  Future<void> setTaskGradientWidth(double value) => _set(AppConstants.keyTaskGradientWidth, value.toString());
  Future<void> setCompactMode(bool value) => _set(AppConstants.keyCompactMode, value.toString());
  Future<void> setShowDescriptionOnCard(bool value) => _set(AppConstants.keyShowDescriptionOnCard, value.toString());
  Future<void> setDefaultPriority(String priority) => _set(AppConstants.keyDefaultPriority, priority);
  Future<void> setDefaultProjectId(String? projectId) => _set(AppConstants.keyDefaultProjectId, projectId ?? 'null');
  Future<void> setHistoryRetention(int days) => _set(AppConstants.keyHistoryRetention, days.toString());
  Future<void> setDefaultStatsPeriod(String period) => _set(AppConstants.keyDefaultStatsPeriod, period);
  Future<void> setShowActiveProjectsOnly(bool value) => _set(AppConstants.keyShowActiveProjectsOnly, value.toString());
  Future<void> setEnableRandomTask(bool value) => _set(AppConstants.keyEnableRandomTask, value.toString());
  Future<void> setFilterInteractionMethod(FilterInteractionMethod method) =>
      _set(AppConstants.keyFilterInteractionMethod, method.name);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
