import 'package:flutter/foundation.dart';

@immutable
sealed class RightSidebarPanel {
  const RightSidebarPanel();
}

class AddTaskPanel extends RightSidebarPanel {
  final DateTime? initialDate;
  final String? initialProjectId;
  final String? initialParentId;

  const AddTaskPanel({
    this.initialDate,
    this.initialProjectId,
    this.initialParentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddTaskPanel &&
          runtimeType == other.runtimeType &&
          initialDate == other.initialDate &&
          initialProjectId == other.initialProjectId &&
          initialParentId == other.initialParentId;

  @override
  int get hashCode =>
      Object.hash(initialDate, initialProjectId, initialParentId);
}

class EditTaskPanel extends RightSidebarPanel {
  final String taskId;

  const EditTaskPanel(this.taskId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditTaskPanel &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;
}

class AddProjectPanel extends RightSidebarPanel {
  const AddProjectPanel();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AddProjectPanel;

  @override
  int get hashCode => runtimeType.hashCode;
}

class EditProjectPanel extends RightSidebarPanel {
  final String projectId;

  const EditProjectPanel(this.projectId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditProjectPanel &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId;

  @override
  int get hashCode => projectId.hashCode;
}

class ActionHistoryPanel extends RightSidebarPanel {
  const ActionHistoryPanel();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ActionHistoryPanel;

  @override
  int get hashCode => runtimeType.hashCode;
}

@immutable
class RightSidebarState {
  final RightSidebarPanel? activePanel;
  final List<RightSidebarPanel> history;

  const RightSidebarState({this.activePanel, this.history = const []});

  bool get isOpen => activePanel != null;

  RightSidebarState copyWith({
    RightSidebarPanel? activePanel,
    bool clearActivePanel = false,
    List<RightSidebarPanel>? history,
  }) {
    return RightSidebarState(
      activePanel: clearActivePanel ? null : (activePanel ?? this.activePanel),
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RightSidebarState &&
          runtimeType == other.runtimeType &&
          activePanel == other.activePanel &&
          listEquals(history, other.history);

  @override
  int get hashCode => Object.hash(activePanel, Object.hashAll(history));
}
