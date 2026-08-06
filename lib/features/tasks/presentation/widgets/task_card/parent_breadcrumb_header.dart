import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentBreadcrumbHeader extends ConsumerStatefulWidget {
  final String parentId;

  const ParentBreadcrumbHeader({super.key, required this.parentId});

  @override
  ConsumerState<ParentBreadcrumbHeader> createState() =>
      _ParentBreadcrumbHeaderState();
}

class _ParentBreadcrumbHeaderState
    extends ConsumerState<ParentBreadcrumbHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final parentTaskAsync = ref.watch(parentTaskProvider(widget.parentId));
    final parentTask = parentTaskAsync.valueOrNull;
    if (parentTask == null) return const SizedBox.shrink();

    final cleanTitle = TagParser.hideHashtagSymbols(parentTask.title);

    final color = _isHovered
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return InkWell(
      onTap: () {
        context.openRightSidebar(EditTaskPanel(parentTask.id), ref);
      },
      onHover: (hovering) => setState(() => _isHovered = hovering),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 11,
              color: color,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                cleanTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
