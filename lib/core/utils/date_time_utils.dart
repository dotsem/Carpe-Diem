/*
Returns true if the date is Friday, Saturday, or Sunday.
*/
bool isEndOfWorkWeek(DateTime date) {
  if (date.weekday == DateTime.friday || date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    return true;
  }
  return false;
}

bool todayIsEndOfWorkWeek() {
  return isEndOfWorkWeek(DateTime.now());
}

extension DateTimeExtension on DateTime {
  DateTime next(int day) {
    if (day == weekday) {
      return add(const Duration(days: 7));
    } else {
      return add(Duration(days: (day - weekday) % DateTime.daysPerWeek));
    }
  }

  DateTime startOfNextWeek(int firstDayOfWeek) => next(firstDayOfWeek);

  DateTime startOfWeek(int firstDayOfWeek) {
    int dayOffset = (weekday - firstDayOfWeek) % DateTime.daysPerWeek;
    return DateTime(year, month, day).subtract(Duration(days: dayOffset));
  }

  bool isStartOfWeek(int firstDayOfWeek) => weekday == firstDayOfWeek;

  bool isSameDay(DateTime? other) {
    if (other == null) return false;
    return year == other.year && month == other.month && day == other.day;
  }

  bool isBeforeDay(DateTime? other) {
    if (other == null) return false;
    return year < other.year ||
        (year == other.year && (month < other.month || (month == other.month && day < other.day)));
  }

  bool isAfterDay(DateTime? other) {
    if (other == null) return false;
    return year > other.year ||
        (year == other.year && (month > other.month || (month == other.month && day > other.day)));
  }

  DateTime startOfMonth() => DateTime(year, month, 1);
  DateTime endOfMonth() => DateTime(year, month + 1, 0);

  bool isBetween(DateTime start, DateTime end) {
    return (isAfterDay(start) || isSameDay(start)) && (isBeforeDay(end) || isSameDay(end));
  }

  bool get isTomorrow {
    final now = DateTime.now();
    return isSameDay(DateTime(now.year, now.month, now.day + 1));
  }

  bool get isToday => isSameDay(DateTime.now());

  int get daysFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return normalize.difference(today).inDays;
  }

  DateTime get normalize => DateTime(year, month, day);
}
