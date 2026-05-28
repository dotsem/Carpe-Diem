import 'package:flutter/widgets.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';

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

final globalShortcutEntries = [
  const ShortcutEntry(key: TodayKeys.upper, description: 'Go to Today', category: 'Navigation'),
  const ShortcutEntry(key: BacklogKeys.upper, description: 'Go to Backlog', category: 'Navigation'),
  const ShortcutEntry(key: ProjectsKeys.upper, description: 'Go to Projects', category: 'Navigation'),
  const ShortcutEntry(key: HistoryKeys.upper, description: 'Go to History', category: 'Navigation'),
  const ShortcutEntry(key: DownKeys.char, description: 'Move Focus Down', category: 'Navigation'),
  const ShortcutEntry(key: UpKeys.char, description: 'Move Focus Up', category: 'Navigation'),
  const ShortcutEntry(key: HelpKeys.char, description: 'Toggle shortcut help', category: 'Global'),
  const ShortcutEntry(key: 'Alt', description: 'Hold to show hints', category: 'Global'),
];

final homeShortcutEntries = [
  const ShortcutEntry(
    key: '${LeftKeys.char} / ${RightKeys.char}',
    description: 'Prev / Next day',
    category: 'Today View',
  ),
  const ShortcutEntry(
    key: '${DownKeys.char} / ${UpKeys.char}',
    description: 'Focus next / prev',
    category: 'Today View',
  ),
  const ShortcutEntry(key: AddKeys.char, description: 'Add new task', category: 'Today View'),
  const ShortcutEntry(key: ToggleLayoutKeys.char, description: 'Toggle layout', category: 'Today View'),
  const ShortcutEntry(key: FilterKeys.char, description: 'Open filter', category: 'Today View'),
  const ShortcutEntry(
    key: 'Shift + ${FilterKeys.upper}',
    description: 'Toggle filter bypass',
    category: 'Today View',
  ),
];

final taskCardShortcutEntries = [
  const ShortcutEntry(key: 'Space', description: 'Toggle completion', category: 'Focused Task'),
  const ShortcutEntry(key: 'Enter', description: 'Toggle completion', category: 'Focused Task'),
  const ShortcutEntry(key: EditKeys.char, description: 'Edit task', category: 'Focused Task'),
  const ShortcutEntry(key: DeleteKeys.char, description: 'Delete task', category: 'Focused Task'),
  const ShortcutEntry(
    key: 'Ctrl + ${TodayKeys.upper}',
    description: 'Plan for today, plans all selected tasks',
    category: 'Focused Task',
  ),
  const ShortcutEntry(
    key: 'Ctrl + Shift + ${TodayKeys.upper}',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];

final projectShortcutEntries = [
  const ShortcutEntry(
    key: '${LeftKeys.char} / ${DownKeys.char} / ${UpKeys.char} / ${RightKeys.char}',
    description: 'Move focus',
    category: 'Projects View',
  ),
  const ShortcutEntry(key: SearchKeys.char, description: 'Focus search', category: 'Projects View'),
  const ShortcutEntry(key: FilterKeys.char, description: 'Open filter', category: 'Projects View'),
  const ShortcutEntry(
    key: 'Shift + ${FilterKeys.upper}',
    description: 'Toggle filter bypass',
    category: 'Projects View',
  ),
];

final taskDialogShortcutEntries = [
  const ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Task Editor'),
  const ShortcutEntry(key: 'Ctrl + P', description: 'Open project menu', category: 'Task Editor'),
  const ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Task Editor'),
  const ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Task Editor'),
];

final projectDialogShortcutEntries = [
  const ShortcutEntry(key: 'Ctrl + 1..5', description: 'Set priority', category: 'Project Editor'),
  const ShortcutEntry(key: 'Ctrl + Enter', description: 'Save changes', category: 'Project Editor'),
  const ShortcutEntry(key: 'Esc', description: 'Cancel / Close', category: 'Project Editor'),
];

final backlogShortcutEntries = [
  const ShortcutEntry(
    key: '${DownKeys.char} / ${UpKeys.char}',
    description: 'Focus next / prev',
    category: 'Backlog',
  ),
  const ShortcutEntry(key: AddKeys.char, description: 'Add new task', category: 'Backlog'),
  const ShortcutEntry(key: SearchKeys.char, description: 'Focus search', category: 'Backlog'),
  const ShortcutEntry(key: FilterKeys.char, description: 'Open filter', category: 'Backlog'),
  const ShortcutEntry(
    key: 'Shift + ${FilterKeys.upper}',
    description: 'Toggle filter bypass',
    category: 'Backlog',
  ),
  const ShortcutEntry(
    key: 'Ctrl + ${TodayKeys.upper}',
    description: 'Plan for today, plans all selected tasks',
    category: 'Focused Task',
  ),
  const ShortcutEntry(
    key: 'Ctrl + Shift + ${TodayKeys.upper}',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];

final projectDetailShortcutEntries = [
  const ShortcutEntry(
    key: '${DownKeys.char} / ${UpKeys.char}',
    description: 'Focus next / prev',
    category: 'Project Detail',
  ),
  const ShortcutEntry(key: AddKeys.char, description: 'Add new task', category: 'Project Detail'),
  const ShortcutEntry(key: SearchKeys.char, description: 'Focus search', category: 'Project Detail'),
  const ShortcutEntry(key: FilterKeys.char, description: 'Open filter', category: 'Project Detail'),
  const ShortcutEntry(
    key: 'Shift + ${FilterKeys.upper}',
    description: 'Toggle filter bypass',
    category: 'Project Detail',
  ),
  const ShortcutEntry(
    key: 'Ctrl + ${TodayKeys.upper}',
    description: 'Plan for today, plans all selected tasks',
    category: 'Focused Task',
  ),
  const ShortcutEntry(
    key: 'Ctrl + Shift + ${TodayKeys.upper}',
    description: 'Plan for tomorrow, plans all selected tasks',
    category: 'Focused Task',
  ),
];
