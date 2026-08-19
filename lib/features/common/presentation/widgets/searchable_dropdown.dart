import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T?> onChanged;
  final String Function(T? item) nameGetter;
  final Widget Function(T? item)? leadingBuilder;
  final String hintText;
  final String searchHint;
  final String emptyText;
  final Widget? prefixIcon;
  final MenuController? menuController;
  final bool borderless;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.nameGetter,
    this.leadingBuilder,
    this.hintText = 'Select item',
    this.searchHint = 'Search...',
    this.emptyText = 'No items found',
    this.prefixIcon,
    this.menuController,
    this.borderless = false,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final MenuController _localMenuController = MenuController();
  MenuController get _menuController =>
      widget.menuController ?? _localMenuController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedIndex = -1;

  List<T?> get _filteredItems {
    final all = <T?>[null, ...widget.items];
    if (_searchQuery.isEmpty) return all;

    return FuzzySearchUtils.search<T?>(
      query: _searchQuery,
      items: all,
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
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) {
            return KeyEventResult.ignored;
          }
          if (_selectedIndex >= 0 && _selectedIndex < items.length) {
            _onItemSelected(items[_selectedIndex]);
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const itemHeight = 40.0;
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

  void _onItemSelected(T? item) {
    widget.onChanged(item);
    _menuController.close();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedText = widget.nameGetter(widget.selectedItem);

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        _searchController.clear();
        _searchFocusNode.requestFocus();
        setState(() {
          _searchQuery = '';
          _selectedIndex = 0;
        });
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHigh,
        ),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      _onItemSelected(_filteredItems[_selectedIndex]);
                    } else {
                      _searchFocusNode.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _filteredItems.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.emptyText,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : List.generate(_filteredItems.length, (index) {
                              final item = _filteredItems[index];
                              final isHighlighted = index == _selectedIndex;
                              return _buildItemRow(
                                context,
                                item,
                                isHighlighted,
                                index,
                              );
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
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: InputDecorator(
            decoration: widget.borderless
                ? InputDecoration(
                    hintText: widget.hintText,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  )
                : InputDecoration(
                    hintText: widget.hintText,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
            child: Row(
              children: [
                if (widget.leadingBuilder != null) ...[
                  widget.leadingBuilder!(widget.selectedItem),
                  const SizedBox(width: 8),
                ] else if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selectedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    T? item,
    bool isHighlighted,
    int index,
  ) {
    final theme = Theme.of(context);
    final label = widget.nameGetter(item);

    return InkWell(
      onTap: () => _onItemSelected(item),
      onHover: (hovering) {
        if (hovering) setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.accent.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (widget.leadingBuilder != null) ...[
              widget.leadingBuilder!(item),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isHighlighted
                      ? AppColors.accent
                      : theme.colorScheme.onSurface,
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
