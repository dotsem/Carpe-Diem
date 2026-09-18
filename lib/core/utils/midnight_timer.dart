import 'dart:async';
import 'package:flutter/widgets.dart';

class MidnightTimer with WidgetsBindingObserver {
  final DateTime Function() _clock;
  VoidCallback? _onDayChanged;
  Timer? _timer;
  Timer? _heartbeatTimer;
  late DateTime _lastDateCheck;

  /// clock is injected for testability, defaults to DateTime.now
  MidnightTimer({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _lastDateCheck = _clock();
  }

  /// starts the midnight timer and calls the callback on midnight.
  void start(VoidCallback onDayChanged) {
    _onDayChanged = onDayChanged;
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMidnight();
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkDayChange(),
    );
  }

  void _scheduleNextMidnight() {
    _timer?.cancel();
    final now = _clock();
    _lastDateCheck = now;
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now) + const Duration(seconds: 1);

    _timer = Timer(duration, _onTimerFired);
  }

  void _onTimerFired() {
    checkDayChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkDayChange();
    }
  }

  /// checks whether the day changed since last check and reschedules midnight if needed.
  void checkDayChange() {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastDateCheck.year,
      _lastDateCheck.month,
      _lastDateCheck.day,
    );

    if (today.isAfter(lastDate)) {
      _lastDateCheck = now;
      _onDayChanged?.call();
      _scheduleNextMidnight();
    }
  }

  void dispose() {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _onDayChanged = null;
  }
}
