import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';

class TagAutocompleteTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool autofocus;

  const TagAutocompleteTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.autofocus = false,
  });

  @override
  ConsumerState<TagAutocompleteTextField> createState() => _TagAutocompleteTextFieldState();
}

class _TagAutocompleteTextFieldState extends ConsumerState<TagAutocompleteTextField> {
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
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
      final query = _activeQuery;
      if (query == null) return KeyEventResult.ignored;

      final suggestions = allTags.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
      if (suggestions.isEmpty) return KeyEventResult.ignored;

      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % suggestions.length;
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + suggestions.length) % suggestions.length;
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _selectTag(suggestions[_selectedIndex]);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            _activeQuery = null;
          });
          _overlayController.hide();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
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
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;

    final selection = widget.controller.selection;
    final activeQuery = TagParser.getActiveQuery(widget.controller.text, selection.baseOffset);

    if (activeQuery != null) {
      final query = activeQuery.query;
      final allTags = ref.read(tagProvider).tags;
      final suggestions = allTags.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();

      setState(() {
        if (_activeQuery != query) {
          _selectedIndex = 0;
        }
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
      setState(() {
        _activeQuery = null;
        _queryStart = null;
        _queryEnd = null;
        _selectedIndex = 0;
      });
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
    final text = widget.controller.text;
    final before = text.substring(0, _queryStart!);
    final after = text.substring(_queryEnd!);
    final newText = '$before#${tag.name} $after';

    widget.controller.text = newText;
    final newCursorOffset = _queryStart! + tag.name.length + 2;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorOffset.clamp(0, newText.length)),
    );

    setState(() {
      _activeQuery = null;
      _queryStart = null;
      _queryEnd = null;
      _selectedIndex = 0;
    });
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(tagProvider).tags;
    final query = _activeQuery;
    final suggestions = query == null
        ? <Tag>[]
        : allTags.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();

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
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < suggestions.length; i++) ...[
                          _SuggestionItem(
                            tag: suggestions[i],
                            isSelected: i == _selectedIndex,
                            icon: tagIcons[suggestions[i].name.trim().toLowerCase()] ?? Icons.tag,
                            onTap: () => _selectTag(suggestions[i]),
                          ),
                        ],
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

class _SuggestionItem extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionItem({required this.tag, required this.isSelected, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '#${tag.name}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
