import 'package:flutter/material.dart';

/// A [MenuController] that runs [onWillOpen] first, so sibling menus can close.
class CoordinatedMenuController extends MenuController {
  final VoidCallback onWillOpen;

  CoordinatedMenuController({required this.onWillOpen});

  @override
  void open({Offset? position}) {
    onWillOpen();
    super.open(position: position);
  }
}

/// The task form's dropdown menus; opening one closes the others.
class TaskFormMenuControllers {
  late final List<MenuController> _all = [project, blocker, label, tag];
  late final MenuController project = _create();
  late final MenuController blocker = _create();
  late final MenuController label = _create();
  late final MenuController tag = _create();

  MenuController _create() {
    late final CoordinatedMenuController c;
    return c = CoordinatedMenuController(
      onWillOpen: () {
        for (final other in _all) {
          if (!identical(other, c) && other.isOpen) other.close();
        }
      },
    );
  }
}
