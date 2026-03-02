import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlockerPicker extends StatefulWidget {
  final List<Task> availableTasks;
  final String? selectedBlockerId;
  final String? currentTaskId;
  final Function(String?) onChanged;

  const BlockerPicker({
    super.key,
    required this.availableTasks,
    required this.onChanged,
    this.selectedBlockerId,
    this.currentTaskId,
  });

  @override
  State<BlockerPicker> createState() => _BlockerPickerState();
}

class _BlockerPickerState extends State<BlockerPicker> {
  final MenuController _menuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int _selectedIndex = -1;

  List<Task?> get _selectableItems {
    final filtered = widget.availableTasks
        .where((t) => !t.isCompleted)
        .where((t) => t.id != widget.currentTaskId)
        .where((t) => !_wouldCreateCycle(t.id))
        .toList();

    final all = <Task?>[null, ...filtered];
    if (_searchQuery.isEmpty) return all;

    return all.where((t) {
      if (t == null) return 'none'.contains(_searchQuery.toLowerCase());
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _wouldCreateCycle(String candidateId) {
    if (widget.currentTaskId == null) return false;
    final taskMap = {for (final t in widget.availableTasks) t.id: t};
    var current = taskMap[candidateId];
    final visited = <String>{};
    while (current != null && current.blockedById != null) {
      if (visited.contains(current.id)) return true;
      visited.add(current.id);
      if (current.blockedById == widget.currentTaskId) return true;
      current = taskMap[current.blockedById];
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() => _selectedIndex = (_selectedIndex + 1) % _selectableItems.length);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() => _selectedIndex = (_selectedIndex - 1 + _selectableItems.length) % _selectableItems.length);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex >= 0 && _selectedIndex < _selectableItems.length) {
            _onSelected(_selectableItems[_selectedIndex]);
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSelected(Task? task) {
    widget.onChanged(task?.id);
    _menuController.close();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTask = widget.selectedBlockerId == null
        ? null
        : widget.availableTasks.where((t) => t.id == widget.selectedBlockerId).firstOrNull;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        _searchFocusNode.requestFocus();
        setState(() => _selectedIndex = 0);
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceLight),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _selectableItems.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text('No tasks available', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              ),
                            ]
                          : List.generate(_selectableItems.length, (index) {
                              final task = _selectableItems[index];
                              return _buildItem(task, index == _selectedIndex, index);
                            }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: InputDecorator(
            decoration: const InputDecoration(
              hintText: 'Blocked by',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: Row(
              children: [
                Icon(
                  selectedTask != null ? Icons.link : Icons.link_off,
                  size: 16,
                  color: selectedTask != null ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(selectedTask?.title ?? 'No blocker', overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) => setState(() {
        _searchQuery = value;
        _selectedIndex = 0;
      }),
    );
  }

  Widget _buildItem(Task? task, bool isHighlighted, int index) {
    return InkWell(
      onTap: () => _onSelected(task),
      onHover: (hovering) {
        if (hovering) setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.accent.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              task == null ? Icons.block : Icons.task_alt,
              size: 14,
              color: isHighlighted ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task?.title ?? 'No blocker',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isHighlighted ? AppColors.accent : AppColors.text,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
