import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/data/models/label.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/ui/widgets/chip/label_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const ProjectCard({super.key, required this.project, this.onTap, this.focusNode});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isFocused = false;

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
                            ? widget.project.priority.color
                            : AppColors.textSecondary.withValues(alpha: 0.3),
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
                            decoration: BoxDecoration(color: widget.project.color, shape: BoxShape.circle),
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
                            decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
                            child: Icon(
                              widget.project.priority.icon,
                              size: 16,
                              color: widget.project.priority.color,
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
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (widget.project.deadline != null) ...[
                        const SizedBox(height: 8),
                        _DeadlineRow(deadline: widget.project.deadline!),
                      ],
                      const SizedBox(height: 12),
                      Consumer<LabelProvider>(
                        builder: (context, labelProvider, _) {
                          final labels = widget.project.labelIds
                              .map((id) => labelProvider.getById(id))
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
                        },
                      ),
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
        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'Deadline: ${months[deadline.month - 1]} ${deadline.day}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
