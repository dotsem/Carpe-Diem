import 'package:carpe_diem/core/theme/animation_context.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDragProxy extends ConsumerStatefulWidget {
  final Task task;
  final int selectedCount;
  final double width;

  const TaskDragProxy({
    super.key,
    required this.task,
    required this.selectedCount,
    required this.width,
  });

  @override
  ConsumerState<TaskDragProxy> createState() => _TaskDragProxyState();
}

class _TaskDragProxyState extends ConsumerState<TaskDragProxy>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _angle = 0.0;
  double _angularVelocity = 0.0;
  double _targetAngle = 0.0;
  Duration _lastTick = Duration.zero;
  DateTime? _lastPointerMoveTime;
  double? _lastPointerX;

  static const double _stiffness = 196.0;
  static const double _damping = 12.6;
  double get _widthScale => (300.0 / widget.width).clamp(0.25, 1.0);
  double get _maxAngle => 0.14 * _widthScale;
  Alignment _pivot = const Alignment(0.0, -1.2);
  bool _pivotInitialized = false;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
    _ticker.dispose();
    super.dispose();
  }

  bool get _animationsEnabled =>
      ref.read(settingsProvider).animationsEnabled && context.animationsEnabled;

  void _handlePointer(PointerEvent event) {
    if (event is! PointerMoveEvent || !_animationsEnabled) return;

    if (!_pivotInitialized) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0) {
        final localX = box.globalToLocal(event.position).dx;
        final ax = ((localX / box.size.width) * 2.0 - 1.0).clamp(-1.0, 1.0);
        _pivot = Alignment(ax, -1.2);
        _pivotInitialized = true;
      }
    }

    final now = DateTime.now();
    if (_lastPointerMoveTime != null && _lastPointerX != null) {
      final elapsedMs =
          now.difference(_lastPointerMoveTime!).inMicroseconds / 1000.0;
      if (elapsedMs > 0 && elapsedMs < 200) {
        final vx = (event.position.dx - _lastPointerX!) / (elapsedMs / 1000.0);
        _targetAngle = (-vx * 0.00018 * _widthScale).clamp(
          -_maxAngle,
          _maxAngle,
        );
      }
    }
    _lastPointerX = event.position.dx;
    _lastPointerMoveTime = now;

    if (!_ticker.isActive && mounted) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    if (_lastPointerMoveTime != null &&
        DateTime.now().difference(_lastPointerMoveTime!).inMilliseconds > 40) {
      _targetAngle = 0.0;
    }

    final acc =
        -_stiffness * (_angle - _targetAngle) - _damping * _angularVelocity;
    _angularVelocity += acc * dt;
    _angle = (_angle + _angularVelocity * dt).clamp(-_maxAngle, _maxAngle);

    if (_targetAngle == 0.0 &&
        _angle.abs() < 0.0005 &&
        _angularVelocity.abs() < 0.005) {
      _angle = 0.0;
      _angularVelocity = 0.0;
      _ticker.stop();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final project = widget.task.projectId != null
        ? ref.watch(projectProvider).getById(widget.task.projectId!)
        : null;

    final cardContent = Material(
      color: Colors.transparent,
      elevation: 0,
      child: Transform.scale(
        scale: 1.02,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: widget.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  child: BaseTaskCard(
                    task: widget.task,
                    project: project,
                    compactMode: settings.compactMode,
                    showDescriptionOnCard: settings.showDescriptionOnCard,
                    showHashtagInTitle: settings.showHashtagInTitle,
                    taskGradientWidth: settings.taskGradientWidth,
                    isOverdue: widget.task.isOverdue,
                  ),
                ),
                if (widget.selectedCount > 1)
                  Transform.translate(
                    offset: Offset(0, settings.compactMode ? -14 : -16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.6),
                            thickness: 3,
                            indent: 8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '+ ${widget.selectedCount - 1} task${widget.selectedCount - 1 != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.6),
                            thickness: 3,
                            endIndent: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final effectiveAngle =
        (settings.animationsEnabled && context.animationsEnabled)
        ? _angle
        : 0.0;

    return Transform.rotate(
      angle: effectiveAngle,
      alignment: _pivot,
      child: cardContent,
    );
  }
}
