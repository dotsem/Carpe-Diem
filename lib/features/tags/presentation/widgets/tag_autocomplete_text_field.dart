import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_suggestion_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

// TODO: revisit this file & clean up
class TagAutocompleteTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool autofocus;
  final void Function(Tag)? onTagSelected;

  const TagAutocompleteTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.autofocus = false,
    this.onTagSelected,
  });

  @override
  ConsumerState<TagAutocompleteTextField> createState() =>
      _TagAutocompleteTextFieldState();
}

class _TagAutocompleteTextFieldState
    extends ConsumerState<TagAutocompleteTextField> {
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _scrollController = ScrollController();
  late final FocusNode _focusNode;

  String? _activeQuery;
  int? _queryStart;
  int? _queryEnd;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _focusNode.onKeyEvent = (node, event) {
      if (!_overlayController.isShowing) return KeyEventResult.ignored;

      final allTags = ref.read(tagProvider).tags;
      final suggestions = _filterSuggestions(allTags, _activeQuery);
      if (suggestions.isEmpty) return KeyEventResult.ignored;

      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _updateSelectedIndex((_selectedIndex + 1) % suggestions.length);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _updateSelectedIndex(
            (_selectedIndex - 1 + suggestions.length) % suggestions.length,
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (isControlOrMetaPressed()) return KeyEventResult.ignored;
          _selectTag(suggestions[_selectedIndex]);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _resetQuery();
          _overlayController.hide();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _updateSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
    _scrollToIndex(index);
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const itemHeight = 36.0;
    final itemTop = index * itemHeight;
    final itemBottom = itemTop + itemHeight;
    final scrollOffset = _scrollController.offset;
    final viewport = _scrollController.position.viewportDimension;

    if (itemBottom > scrollOffset + viewport) {
      _scrollController.animateTo(
        (itemBottom - viewport).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (itemTop < scrollOffset) {
      _scrollController.animateTo(
        itemTop.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(TagAutocompleteTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  List<Tag> _filterSuggestions(List<Tag> allTags, String? query) {
    if (query == null) return const [];
    final lower = query.toLowerCase();
    return allTags.where((t) => t.name.toLowerCase().contains(lower)).toList();
  }

  void _resetQuery() {
    setState(() {
      _activeQuery = null;
      _queryStart = null;
      _queryEnd = null;
      _selectedIndex = 0;
    });
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;

    final selection = widget.controller.selection;
    final activeQuery = TagParser.getActiveQuery(
      widget.controller.text,
      selection.baseOffset,
    );

    if (activeQuery != null) {
      final query = activeQuery.query;
      final allTags = ref.read(tagProvider).tags;
      final suggestions = _filterSuggestions(allTags, query);

      if (_activeQuery != query && _scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }

      setState(() {
        if (_activeQuery != query) _selectedIndex = 0;
        _activeQuery = query;
        _queryStart = activeQuery.startIndex;
        _queryEnd = activeQuery.endIndex;
      });
      if (suggestions.isNotEmpty) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    } else {
      _resetQuery();
      _overlayController.hide();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _overlayController.hide();
    } else {
      _onTextChanged();
    }
  }

  void _selectTag(Tag tag) {
    if (_queryStart == null || _queryEnd == null) return;
    final start = _queryStart!;
    final end = _queryEnd!;
    final text = widget.controller.text;
    final before = text.substring(0, start);
    final after = text.substring(end);

    final keepTagsInTitle = ref.read(settingsProvider).keepTagsInTitle;
    final newText = keepTagsInTitle
        ? '$before#${tag.name} $after'
        : '$before $after'.replaceAll(RegExp(r'\s+'), ' ').trimLeft();
    final newCursorOffset = keepTagsInTitle
        ? start + tag.name.length + 2
        : before.length.clamp(0, newText.length);

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorOffset.clamp(0, newText.length)),
    );

    widget.onTagSelected?.call(tag);
    _resetQuery();
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(tagProvider).tags;
    final suggestions = _filterSuggestions(allTags, _activeQuery);

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        final width = _layerLink.leaderSize?.width ?? 300.0;
        final tagIcons = ref.watch(tagIconProvider);

        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < suggestions.length; i++)
                          TagSuggestionItem(
                            tag: suggestions[i],
                            isSelected: i == _selectedIndex,
                            icon:
                                tagIcons[suggestions[i].name
                                    .trim()
                                    .toLowerCase()] ??
                                Icons.tag,
                            onTap: () => _selectTag(suggestions[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          decoration: widget.decoration,
          style: widget.style,
        ),
      ),
    );
  }
}
