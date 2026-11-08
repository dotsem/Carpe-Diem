import 'package:carpe_diem/core/utils/date_time_utils.dart';

enum DeadlineUrgency {
  none,
  approaching,
  imminent,
  overdue;

  /// [today] is expected to be a normalized date.
  static DeadlineUrgency of(DateTime deadline, DateTime today) {
    final days = today.daysUntil(deadline);
    if (days < 0) return overdue;
    if (days <= 1) return imminent;
    if (days <= 3) return approaching;
    return none;
  }
}
