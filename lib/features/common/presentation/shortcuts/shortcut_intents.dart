import 'package:flutter/widgets.dart';

class NavigateToTodayIntent extends Intent {
  const NavigateToTodayIntent();
}

class NavigateToBacklogIntent extends Intent {
  const NavigateToBacklogIntent();
}

class NavigateToProjectsIntent extends Intent {
  const NavigateToProjectsIntent();
}

class NavigateToHistoryIntent extends Intent {
  const NavigateToHistoryIntent();
}

class PrevDayIntent extends Intent {
  const PrevDayIntent();
}

class NextDayIntent extends Intent {
  const NextDayIntent();
}

class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class ToggleLayoutIntent extends Intent {
  const ToggleLayoutIntent();
}

class ToggleHelpIntent extends Intent {
  const ToggleHelpIntent();
}

class CloseHelpIntent extends Intent {
  const CloseHelpIntent();
}

class MoveNextIntent extends Intent {
  const MoveNextIntent();
}

class MovePrevIntent extends Intent {
  const MovePrevIntent();
}

class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

class FilterIntent extends Intent {
  const FilterIntent();
}

class ToggleFilterBypassIntent extends Intent {
  const ToggleFilterBypassIntent();
}

class PlanTaskIntent extends Intent {
  const PlanTaskIntent();
}

class PlanTaskTomorrowIntent extends Intent {
  const PlanTaskTomorrowIntent();
}

class ShortcutEntry {
  final String key;
  final String description;
  final String category;

  const ShortcutEntry({
    required this.key,
    required this.description,
    required this.category,
  });
}

const globalShortcutEntries = [
  ShortcutEntry(key: 'T', description: 'Go to Today', category: 'Navigation'),
  ShortcutEntry(key: 'B', description: 'Go to Backlog', category: 'Navigation'),
  ShortcutEntry(key: 'P', description: 'Go to Projects', category: 'Navigation'),
  ShortcutEntry(key: 'Y', description: 'Go to History', category: 'Navigation'),
  ShortcutEntry(key: 'j', description: 'Move Focus Down', category: 'Navigation'),
  ShortcutEntry(key: 'k', description: 'Move Focus Up', category: 'Navigation'),
  ShortcutEntry(key: '?', description: 'Toggle shortcut help', category: 'Global'),
  ShortcutEntry(key: 'Alt', description: 'Hold to show hints', category: 'Global'),
];

const homeShortcutEntries = [
  ShortcutEntry(key: 'h / l', description: 'Prev / Next day', category: 'Today View'),
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Today View'),
  ShortcutEntry(key: 'a', description: 'Add new task', category: 'Today View'),
  ShortcutEntry(key: 'v', description: 'Toggle layout', category: 'Today View'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Today View'),
  ShortcutEntry(key: 'Shift + F', description: 'Toggle filter bypass', category: 'Today View'),
];

const taskCardShortcutEntries = [
  ShortcutEntry(key: 'Space', description: 'Toggle completion', category: 'Focused Task'),
  ShortcutEntry(key: 'Enter', description: 'Toggle completion', category: 'Focused Task'),
  ShortcutEntry(key: 'e', description: 'Edit task', category: 'Focused Task'),
  ShortcutEntry(key: 'd', description: 'Delete task', category: 'Focused Task'),
  ShortcutEntry(key: 'Ctrl + T', description: 'Plan for today, plans all selected tasks', category: 'Focused Task'),
  ShortcutEntry(
    key: 'Ctrl + Shift + T',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];

const projectShortcutEntries = [
  ShortcutEntry(key: 'h / j / k / l', description: 'Move focus', category: 'Projects View'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Projects View'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Projects View'),
  ShortcutEntry(key: 'Shift + F', description: 'Toggle filter bypass', category: 'Projects View'),
];

const taskDialogShortcutEntries = [
  ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Task Editor'),
  ShortcutEntry(key: 'Ctrl + P', description: 'Open project menu', category: 'Task Editor'),
  ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Task Editor'),
  ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Task Editor'),
];

const projectDialogShortcutEntries = [
  ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Project Editor'),
  ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Project Editor'),
  ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Project Editor'),
];

const backlogShortcutEntries = [
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Backlog'),
  ShortcutEntry(key: 'a', description: 'Add new task', category: 'Backlog'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Backlog'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Backlog'),
  ShortcutEntry(key: 'Shift + F', description: 'Toggle filter bypass', category: 'Backlog'),
  ShortcutEntry(key: 'Ctrl + T', description: 'Plan for today, plans all selected tasks', category: 'Focused Task'),
  ShortcutEntry(
    key: 'Ctrl + Shift + T',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];

const projectDetailShortcutEntries = [
  ShortcutEntry(key: 'j / k', description: 'Focus next / prev', category: 'Project Detail'),
  ShortcutEntry(key: 'a', description: 'Add new task', category: 'Project Detail'),
  ShortcutEntry(key: '/', description: 'Focus search', category: 'Project Detail'),
  ShortcutEntry(key: 'f', description: 'Open filter', category: 'Project Detail'),
  ShortcutEntry(key: 'Shift + F', description: 'Toggle filter bypass', category: 'Project Detail'),
  ShortcutEntry(key: 'Ctrl + T', description: 'Plan for today, plans all selected tasks', category: 'Focused Task'),
  ShortcutEntry(
    key: 'Ctrl + Shift + T',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];
