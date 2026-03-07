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
      return add(Duration(days: 7));
    } else {
      return add(Duration(days: (day - weekday) % DateTime.daysPerWeek));
    }
  }
}
