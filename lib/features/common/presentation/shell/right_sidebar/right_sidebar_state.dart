import 'package:flutter/foundation.dart';

@immutable
sealed class RightSidebarPanel {
  const RightSidebarPanel();
}

class AddTaskPanel extends RightSidebarPanel {
  final DateTime? initialDate;
  final String? initialProjectId;
  final String? initialParentId;

  const AddTaskPanel({this.initialDate, this.initialProjectId, this.initialParentId});
}

class EditTaskPanel extends RightSidebarPanel {
  final String taskId;

  const EditTaskPanel(this.taskId);
}

class AddProjectPanel extends RightSidebarPanel {
  const AddProjectPanel();
}

class EditProjectPanel extends RightSidebarPanel {
  final String projectId;

  const EditProjectPanel(this.projectId);
}

class ActionHistoryPanel extends RightSidebarPanel {
  const ActionHistoryPanel();
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
}
