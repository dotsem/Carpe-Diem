class AppConstants {
  static const String appName = 'Carpe Diem';
  static const String dbName = 'carpe_diem.db';
  static const int dbVersion = 11;
  // initial values for settings
  static const int firstDayOfWeek = DateTime.monday;
  static const int maxPlanningDaysAhead = 7;
  static const int taskCompletionDelaySeconds = 5;
  static const bool inheritParentDeadline = true;
  static const bool prioritizeDeadlines = true;
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

  // Setting keys
  static const String keyMaxPlanningDays = 'max_planning_days';
  static const String keyFirstDayOfWeek = 'first_day_of_week';
  static const String keyTaskDelay = 'task_delay';
  static const String keyInheritParentDeadline = 'inherit_parent_deadline';
  static const String keyPrioritizeDeadlines = 'prioritize_deadlines';
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
}
