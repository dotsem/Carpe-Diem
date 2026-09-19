import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:carpe_diem/features/command_palette/models/palette_command.dart';
import 'package:carpe_diem/features/command_palette/presentation/utils/command_palette_builder.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette_empty_state.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette_footer.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette_results_list.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette_search_bar.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show([BuildContext? context]) {
    final targetContext = context ?? rootNavigatorKey.currentContext;
    if (targetContext == null) return Future.value();
    return showDialog(
      context: targetContext,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (_) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'PaletteInputFocus');
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  int _selectedIndex = 0;
  List<PaletteCommand> _filteredCommands = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
      _selectedIndex = 0;
    });
  }

  List<PaletteCommand> _getFiltered(List<PaletteCommand> all) {
    if (_query.trim().isEmpty) return all;
    return FuzzySearchUtils.search<PaletteCommand>(
      query: _query,
      items: all,
      itemToString: (c) => c.searchableText,
    );
  }

  void _executeCommand(PaletteCommand command) {
    Navigator.of(context, rootNavigator: true).pop();
    command.onSelect();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredCommands.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredCommands.isNotEmpty) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _filteredCommands.length) %
              _filteredCommands.length;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredCommands.isNotEmpty &&
          _selectedIndex < _filteredCommands.length) {
        _executeCommand(_filteredCommands[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCommands = CommandPaletteBuilder.buildCommands(
      context: context,
      ref: ref,
    );
    _filteredCommands = _getFiltered(allCommands);

    if (_selectedIndex >= _filteredCommands.length &&
        _filteredCommands.isNotEmpty) {
      _selectedIndex = 0;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: KeyboardListener(
          focusNode: FocusNode(skipTraversal: true),
          onKeyEvent: _handleKeyEvent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommandPaletteSearchBar(
                controller: _searchController,
                focusNode: _inputFocusNode,
                query: _query,
                onClear: () => _searchController.clear(),
              ),
              const Divider(height: 1),
              Expanded(
                child: _filteredCommands.isEmpty
                    ? const CommandPaletteEmptyState()
                    : CommandPaletteResultsList(
                        scrollController: _scrollController,
                        filteredCommands: _filteredCommands,
                        selectedIndex: _selectedIndex,
                        onSelectCommand: _executeCommand,
                      ),
              ),
              const Divider(height: 1),
              CommandPaletteFooter(count: _filteredCommands.length),
            ],
          ),
        ),
      ),
    );
  }
}
