class SettingsConstants {
  static const int firstDayOfWeek = DateTime.monday;
  static const int maxPlanningDaysAhead = 7;
  static const int taskCompletionDelaySeconds = 5;
  static const bool inheritParentDeadline = true;
  static const bool prioritizeDeadlines = true;
  static const bool prioritizeOverdue = true;
  static const bool inheritProjectDeadline = false;
  static const double defaultTaskGradientWidth = 0.5;
  static const bool defaultCompactMode = false;
  static const bool defaultShowDescriptionOnCard = true;
  static const String defaultTaskPriority = 'low';
  static const String? defaultProjectId = null;
  static const int defaultHistoryRetention = 0; // 0 = forever
  static const String defaultStatsPeriod = 'weekly';
  static const bool defaultShowActiveProjectsOnly = false;
  static const bool defaultEnableRandomTask = false;
  static const String defaultFilterInteractionMethod = 'cycle';
  static const bool defaultPersistentFilter = false;
  static const Absorption defaultTagAbsorption = Absorption.append;
  static const bool defaultKeepTagsInTitle = true;
  static const bool defaultShowHashtagInTitle = false;

  // Setting keys
  static const String keyMaxPlanningDays = 'max_planning_days';
  static const String keyFirstDayOfWeek = 'first_day_of_week';
  static const String keyTaskDelay = 'task_delay';
  static const String keyInheritParentDeadline = 'inherit_parent_deadline';
  static const String keyPrioritizeDeadlines = 'prioritize_deadlines';
  static const String keyPrioritizeOverdue = 'prioritize_overdue';
  static const String keyInheritProjectDeadline = 'inherit_project_deadline';
  static const String keyThemeMode = 'theme_mode';
  static const String keyTaskGradientWidth = 'task_gradient_width';
  static const String keyCompactMode = 'compact_mode';
  static const String keyShowDescriptionOnCard = 'show_description_on_card';
  static const String keyDefaultPriority = 'default_task_priority';
  static const String keyDefaultProjectId = 'default_project_id';
  static const String keyHistoryRetention = 'history_retention';
  static const String keyDefaultStatsPeriod = 'default_stats_period';
  static const String keyShowActiveProjectsOnly = 'show_active_projects_only';
  static const String keyShowCompletedTasks = 'show_completed_tasks';
  static const String keyEnableRandomTask = 'enable_random_task';
  static const String keyFilterInteractionMethod = 'filter_interaction_method';
  static const String keyPersistentFilter = 'persistent_filter';
  static const String keyPersistentFilterValues = 'persistent_filter_values';
  static const String keyTagAbsorption = 'tag_absorption';
  static const String keyKeepTagsInTitle = 'keep_tags_in_title';
  static const String keyShowHashtagInTitle = 'show_hashtag_in_title';
}

enum Absorption {
  replace,
  append;

  static Absorption fromString(String name) {
    return Absorption.values.firstWhere((e) => e.name == name, orElse: () => Absorption.replace);
  }
}
