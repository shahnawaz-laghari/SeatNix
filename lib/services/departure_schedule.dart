const departureHours = [6, 10, 14, 18, 22];

List<DateTime> departuresFor(DateTime day, DateTime now) {
  return [
    for (final hour in departureHours)
      DateTime(day.year, day.month, day.day, hour),
  ].where((departure) => departure.isAfter(now)).toList();
}

String formatDepartureTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
}
