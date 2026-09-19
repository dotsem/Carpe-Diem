import 'package:flutter/material.dart';
import 'package:carpe_diem/features/command_palette/models/palette_command.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette_list_tile.dart';

class CommandPaletteResultsList extends StatelessWidget {
  final ScrollController scrollController;
  final List<PaletteCommand> filteredCommands;
  final int selectedIndex;
  final ValueChanged<PaletteCommand> onSelectCommand;

  const CommandPaletteResultsList({
    super.key,
    required this.scrollController,
    required this.filteredCommands,
    required this.selectedIndex,
    required this.onSelectCommand,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      itemCount: filteredCommands.length,
      itemBuilder: (context, index) {
        final command = filteredCommands[index];
        return CommandPaletteListTile(
          command: command,
          isSelected: index == selectedIndex,
          onTap: () => onSelectCommand(command),
        );
      },
    );
  }
}
