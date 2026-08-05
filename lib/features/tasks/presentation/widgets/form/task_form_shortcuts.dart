import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:flutter/material.dart';

class TaskFormShortcuts extends StatelessWidget {
  final Widget child;
  final ValueChanged<TaskPlacement> onPlacementChanged;
  final MenuController projectMenuController;
  final VoidCallback onSubmit;

  const TaskFormShortcuts({
    super.key,
    required this.child,
    required this.onPlacementChanged,
    required this.projectMenuController,
    required this.onSubmit,
  });

  void _toggleProjectMenu() {
    if (projectMenuController.isOpen) {
      projectMenuController.close();
    } else {
      projectMenuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(AppKeyBindings.digit1, control: true): () =>
            onPlacementChanged(TaskPlacement.bottom),
        const SingleActivator(AppKeyBindings.digit1, meta: true): () =>
            onPlacementChanged(TaskPlacement.bottom),
        const SingleActivator(AppKeyBindings.digit2, control: true): () =>
            onPlacementChanged(TaskPlacement.middle),
        const SingleActivator(AppKeyBindings.digit2, meta: true): () =>
            onPlacementChanged(TaskPlacement.middle),
        const SingleActivator(AppKeyBindings.digit3, control: true): () =>
            onPlacementChanged(TaskPlacement.top),
        const SingleActivator(AppKeyBindings.digit3, meta: true): () =>
            onPlacementChanged(TaskPlacement.top),
        const SingleActivator(AppKeyBindings.digit4, control: true): () =>
            onPlacementChanged(TaskPlacement.urgent),
        const SingleActivator(AppKeyBindings.digit4, meta: true): () =>
            onPlacementChanged(TaskPlacement.urgent),
        SingleActivator(ProjectsKeys.keyboardKey, control: true):
            _toggleProjectMenu,
        SingleActivator(ProjectsKeys.keyboardKey, meta: true):
            _toggleProjectMenu,
        const SingleActivator(AppKeyBindings.enter, control: true): onSubmit,
        const SingleActivator(AppKeyBindings.enter, meta: true): onSubmit,
      },
      child: child,
    );
  }
}
