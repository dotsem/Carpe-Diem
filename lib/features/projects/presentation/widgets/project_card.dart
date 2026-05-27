import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/label_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectCard extends ConsumerStatefulWidget {
  final Project project;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const ProjectCard({super.key, required this.project, this.onTap, this.focusNode});

  @override
  ConsumerState<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends ConsumerState<ProjectCard> {
  bool _isFocused = false;

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    final projectNotifier = ref.read(projectProvider.notifier);
    final isActive = widget.project.isActive;
    final RenderBox navigatorBox = Navigator.of(context).context.findRenderObject() as RenderBox;
    final Offset navigatorOffset = navigatorBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        navigatorOffset & navigatorBox.size,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
            title: Text(isActive ? 'Archive Project' : 'Restore Project'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () => projectNotifier.toggleProjectActive(widget.project),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.focusNode ?? ChangeNotifier(),
      builder: (context, _) {
        final hasFocus = (widget.focusNode?.hasFocus ?? false) || _isFocused;
        return Opacity(
          opacity: widget.project.isActive ? 1.0 : 0.6,
          child: SizedBox(
            width: 240,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: hasFocus
                    ? BorderSide(color: AppColors.accent, width: 2)
                    : BorderSide(
                        color: widget.project.isActive
                            ? widget.project.priority.color.themeDependentColor(context)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
              ),
              child: InkWell(
                focusNode: widget.focusNode,
                onTap: widget.onTap,
                onFocusChange: (focused) {
                  if (focused && mounted) {
                    Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200), alignment: 0.5);
                  }
                  setState(() => _isFocused = focused);
                },
                onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
                onLongPress: () {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset pos = box.localToGlobal(box.size.center(Offset.zero));
                  _showContextMenu(context, pos);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: widget.project.color.themeDependentColor(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.project.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.project.priority.icon,
                              size: 16,
                              color: widget.project.priority.color.themeDependentColor(context),
                              semanticLabel: widget.project.priority.name,
                            ),
                          ),
                        ],
                      ),
                      if (widget.project.description != null && widget.project.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.project.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (widget.project.deadline != null) ...[
                        const SizedBox(height: 8),
                        _DeadlineRow(deadline: widget.project.deadline!),
                      ],
                      const SizedBox(height: 12),
                      () {
                        final labelState = ref.watch(labelProvider);
                        final labels = widget.project.labelIds
                            .map((id) => labelState.getById(id))
                            .whereType<Label>()
                            .toList();
                        if (labels.isEmpty) return const SizedBox.shrink();

                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: labels.map((label) {
                            return LabelChip(label: label);
                          }).toList(),
                        );
                      }(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// TODO add color when dealine approaches
class _DeadlineRow extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineRow({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          'Deadline: ${months[deadline.month - 1]} ${deadline.day}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
