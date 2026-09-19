import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:carpe_diem/features/command_palette/models/palette_command.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';

class CommandPaletteBuilder {
  static List<PaletteCommand> buildCommands({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final commands = <PaletteCommand>[];

    // Navigation
    commands.addAll([
      PaletteCommand(
        id: 'nav_today',
        title: 'Go to Today',
        subtitle: 'View today scheduled tasks and timeline',
        icon: Icons.wb_sunny_outlined,
        category: CommandCategory.navigation,
        keywords: const ['today', 'tasks', 'schedule', 'home'],
        onSelect: () {
          final today = DateTime.now();
          ref.read(selectedDateProvider.notifier).state = today;
          ref.read(taskProvider.notifier).loadTasksForDate(today);
          appRouter.go('/');
        },
      ),
      PaletteCommand(
        id: 'nav_tomorrow',
        title: 'Go to Tomorrow',
        subtitle: 'View tomorrow scheduled tasks',
        icon: Icons.next_plan_outlined,
        category: CommandCategory.navigation,
        keywords: const ['tomorrow', 'tasks', 'schedule', 'home'],
        onSelect: () {
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          ref.read(selectedDateProvider.notifier).state = tomorrow;
          ref.read(taskProvider.notifier).loadTasksForDate(tomorrow);
          appRouter.go('/');
        },
      ),
      PaletteCommand(
        id: 'nav_backlog',
        title: 'Go to Backlog',
        subtitle: 'View all unscheduled tasks',
        icon: Icons.inbox_outlined,
        category: CommandCategory.navigation,
        keywords: const ['backlog', 'tasks', 'unscheduled', 'inbox'],
        onSelect: () => appRouter.go('/tasks'),
      ),
      PaletteCommand(
        id: 'nav_projects',
        title: 'Go to Projects',
        subtitle: 'Manage all projects and boards',
        icon: Icons.folder_outlined,
        category: CommandCategory.navigation,
        keywords: const ['projects', 'overview', 'manage'],
        onSelect: () => appRouter.go('/projects'),
      ),
      PaletteCommand(
        id: 'nav_history',
        title: 'Go to History',
        subtitle: 'View completed tasks and statistics',
        icon: Icons.history_rounded,
        category: CommandCategory.navigation,
        keywords: const ['history', 'completed', 'archive', 'stats'],
        onSelect: () => appRouter.go('/history'),
      ),
      PaletteCommand(
        id: 'nav_settings',
        title: 'Go to Settings',
        subtitle: 'App preferences, theme, and shortcuts',
        icon: Icons.settings_outlined,
        category: CommandCategory.navigation,
        keywords: const ['settings', 'preferences', 'theme', 'config'],
        onSelect: () => appRouter.go('/settings'),
      ),
    ]);

    // Projects
    final projects = ref
        .read(projectProvider)
        .projects
        .where((p) => p.isActive);
    for (final project in projects) {
      commands.add(
        PaletteCommand(
          id: 'project_${project.id}',
          title: project.name,
          subtitle: project.description?.isNotEmpty == true
              ? project.description
              : 'Project',
          icon: Icons.folder,
          iconColor: project.color,
          category: CommandCategory.projects,
          keywords: ['project', project.name],
          onSelect: () => appRouter.go('/projects/${project.id}'),
        ),
      );
    }

    // Backlog tabs
    commands.add(
      PaletteCommand(
        id: 'nav_backlog_all',
        title: 'Backlog: All Tasks',
        subtitle: 'View all unscheduled tasks',
        icon: Icons.inbox_outlined,
        category: CommandCategory.backlog,
        keywords: const ['backlog', 'tasks', 'all', 'inbox'],
        onSelect: () {
          ref.read(backlogLabelTabProvider.notifier).selectAll();
          appRouter.go('/tasks');
        },
      ),
    );
    final labels = ref.read(labelProvider).labels;
    for (final label in labels) {
      commands.add(
        PaletteCommand(
          id: 'nav_backlog_${label.id}',
          title: 'Backlog: ${label.name}',
          subtitle: 'Filter backlog by label "${label.name}"',
          icon: Icons.label_outline,
          iconColor: label.color,
          category: CommandCategory.backlog,
          keywords: ['label', 'backlog', label.name, 'tasks'],
          onSelect: () {
            ref.read(backlogLabelTabProvider.notifier).selectLabel(label.id);
            appRouter.go('/tasks');
          },
        ),
      );
    }
    commands.add(
      PaletteCommand(
        id: 'nav_backlog_inbox',
        title: 'Backlog: Inbox',
        subtitle: 'View all tasks without label',
        icon: Icons.inbox_outlined,
        category: CommandCategory.backlog,
        keywords: const ['backlog', 'tasks', 'inbox', 'no label', 'unlabeled'],
        onSelect: () {
          ref.read(backlogLabelTabProvider.notifier).selectInbox();
          appRouter.go('/tasks');
        },
      ),
    );

    // Actions
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final undoState = ref.read(undoRedoProvider);

    commands.addAll([
      PaletteCommand(
        id: 'action_new_task',
        title: 'New Task',
        subtitle: 'Create a new task in sidebar',
        icon: Icons.add_task,
        category: CommandCategory.actions,
        keywords: const ['add', 'task', 'create', 'new'],
        onSelect: () => context.openRightSidebar(const AddTaskPanel(), ref),
      ),
      PaletteCommand(
        id: 'action_new_project',
        title: 'New Project',
        subtitle: 'Create a new project in sidebar',
        icon: Icons.create_new_folder_outlined,
        category: CommandCategory.actions,
        keywords: const ['add', 'project', 'create', 'new'],
        onSelect: () => context.openRightSidebar(const AddProjectPanel(), ref),
      ),
      PaletteCommand(
        id: 'action_toggle_theme',
        title: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
        subtitle: 'Toggle application theme appearance',
        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        category: CommandCategory.actions,
        keywords: const ['theme', 'dark', 'light', 'mode', 'appearance'],
        onSelect: () {
          final notifier = ref.read(settingsProvider.notifier);
          notifier.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
        },
      ),
      PaletteCommand(
        id: 'action_toggle_filter_bypass',
        title: 'Toggle Filter Bypass',
        subtitle: 'Temporarily show/hide filtered items',
        icon: Icons.filter_alt_outlined,
        category: CommandCategory.actions,
        keywords: const ['filter', 'bypass', 'hidden'],
        onSelect: () => ref.read(filterProvider.notifier).toggleBypass(),
      ),
      PaletteCommand(
        id: 'action_import_markdown',
        title: 'Import from Markdown',
        subtitle: 'Import tasks from a markdown file',
        icon: Icons.file_upload_outlined,
        category: CommandCategory.actions,
        keywords: const ['import', 'markdown', 'file', 'md'],
        onSelect: () {
          showDialog(
            context: context,
            builder: (_) => const ImportFromMDDialog(),
          );
        },
      ),
      PaletteCommand(
        id: 'action_shortcuts_help',
        title: 'Keyboard Shortcuts Help',
        subtitle: 'View cheat sheet of all available shortcuts',
        icon: Icons.keyboard_outlined,
        category: CommandCategory.actions,
        keywords: const ['shortcuts', 'help', 'keyboard', 'hotkeys'],
        onSelect: () => GlobalShortcuts.maybeOf(context)?.toggleHelp(),
      ),
      if (undoState.canUndo)
        PaletteCommand(
          id: 'action_undo',
          title: 'Undo',
          subtitle: undoState.undoDescription != null
              ? 'Undo: ${undoState.undoDescription}'
              : 'Undo last action',
          icon: Icons.undo,
          category: CommandCategory.actions,
          keywords: const ['undo', 'revert'],
          onSelect: () => ref.read(undoRedoProvider.notifier).undo(),
        ),
      if (undoState.canRedo)
        PaletteCommand(
          id: 'action_redo',
          title: 'Redo',
          subtitle: undoState.redoDescription != null
              ? 'Redo: ${undoState.redoDescription}'
              : 'Redo last action',
          icon: Icons.redo,
          category: CommandCategory.actions,
          keywords: const ['redo'],
          onSelect: () => ref.read(undoRedoProvider.notifier).redo(),
        ),
    ]);

    return commands;
  }
}
