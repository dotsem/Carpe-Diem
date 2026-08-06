import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiSelectSearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<String> selectedIds;
  final List<String> disabledIds;
  final String Function(T item) idGetter;
  final String Function(T item) nameGetter;
  final Widget Function(T item)? leadingBuilder;
  final ValueChanged<List<String>> onChanged;
  final String buttonLabel;
  final String searchHint;
  final bool allowAdd;
  final String addNewLabel;
  final VoidCallback? onAddNew;

  const MultiSelectSearchableDropdown({
    super.key,
    required this.items,
    required this.selectedIds,
    this.disabledIds = const [],
    required this.idGetter,
    required this.nameGetter,
    required this.onChanged,
    this.leadingBuilder,
    this.buttonLabel = '+ Add',
    this.searchHint = 'Search...',
    this.allowAdd = true,
    this.addNewLabel = 'New item',
    this.onAddNew,
  });

  @override
  State<MultiSelectSearchableDropdown<T>> createState() =>
      _MultiSelectSearchableDropdownState<T>();
}

class _MultiSelectSearchableDropdownState<T>
    extends State<MultiSelectSearchableDropdown<T>> {
  final MenuController _menuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedIndex = -1;

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;

    return FuzzySearchUtils.search<T>(
      query: _searchQuery,
      items: widget.items,
      itemToString: (item) => widget.nameGetter(item),
      threshold: 0.3,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        final items = _filteredItems;
        if (items.isEmpty) return KeyEventResult.ignored;

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % items.length;
          });
          _scrollToIndex(_selectedIndex);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + items.length) % items.length;
          });
          _scrollToIndex(_selectedIndex);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex >= 0 && _selectedIndex < items.length) {
            final item = items[_selectedIndex];
            final id = widget.idGetter(item);
            if (!widget.disabledIds.contains(id)) {
              _toggle(id, !widget.selectedIds.contains(id));
            }
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const itemHeight = 44.0;
    final targetOffset = index * itemHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle(String id, bool select) {
    final newIds = List<String>.from(widget.selectedIds);
    if (select) {
      if (!newIds.contains(id)) newIds.add(id);
    } else {
      newIds.remove(id);
    }
    widget.onChanged(newIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        _searchController.clear();
        if (widget.items.length > 5) {
          _searchFocusNode.requestFocus();
        }
        setState(() {
          _searchQuery = '';
          _selectedIndex = 0;
        });
      },
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surfaceContainerHigh,
        ),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.items.length > 5) ...[
                  FuzzySearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: widget.searchHint,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _selectedIndex = 0;
                      });
                    },
                    onSubmitted: (_) {
                      if (_selectedIndex >= 0 &&
                          _selectedIndex < _filteredItems.length) {
                        final item = _filteredItems[_selectedIndex];
                        final id = widget.idGetter(item);
                        if (!widget.disabledIds.contains(id)) {
                          _toggle(id, !widget.selectedIds.contains(id));
                        }
                      } else {
                        _searchFocusNode.requestFocus();
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filtered.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'No items found',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : List.generate(filtered.length, (index) {
                              final item = filtered[index];
                              final id = widget.idGetter(item);
                              final isDisabled =
                                  widget.disabledIds.contains(id);
                              final isSelected =
                                  widget.selectedIds.contains(id) || isDisabled;
                              final isHighlighted = index == _selectedIndex;

                              return MouseRegion(
                                onHover: (_) {
                                  if (_selectedIndex != index) {
                                    setState(() => _selectedIndex = index);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? theme.colorScheme.primary.withAlpha(25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CheckboxListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    title: Text(
                                      widget.nameGetter(item),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    secondary: widget.leadingBuilder?.call(item),
                                    value: isSelected,
                                    enabled: !isDisabled,
                                    onChanged: isDisabled
                                        ? null
                                        : (checked) =>
                                            _toggle(id, checked ?? false),
                                  ),
                                ),
                              );
                            }),
                    ),
                  ),
                ),
                if (widget.allowAdd && widget.onAddNew != null) ...[
                  const Divider(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      _menuController.close();
                      widget.onAddNew!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget.addNewLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return ActionChip(
          label: Text(widget.buttonLabel),
          avatar: const Icon(Icons.add, size: 16),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }
}
