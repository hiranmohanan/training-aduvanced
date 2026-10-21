import 'package:intl/intl.dart';

/// Demo time advances from a repeatable anchor; never uses the host calendar.
class ClockService {
  ClockService({DateTime? anchor, this.frozen = false})
    : _anchor = anchor ?? DateTime.utc(2026, 9, 16, 9) {
    _watch.start();
  }
  DateTime _anchor;
  final bool frozen;
  final Stopwatch _watch = Stopwatch();
  DateTime get now => _anchor.add(frozen ? Duration.zero : _watch.elapsed);
  void reset() {
    _anchor = DateTime.utc(2026, 9, 16, 9);
    _watch.reset();
  }

  static DateTime companyTime(DateTime date) =>
      date.toUtc().add(const Duration(hours: 5, minutes: 30));
  static DateTime fromCompany(DateTime wallTime) => DateTime.utc(
    wallTime.year,
    wallTime.month,
    wallTime.day,
    wallTime.hour,
    wallTime.minute,
  ).subtract(const Duration(hours: 5, minutes: 30));
  static String date(DateTime value) =>
      DateFormat('d MMM yyyy').format(companyTime(value));
  static String shortDate(DateTime value) =>
      DateFormat('d MMM').format(companyTime(value));
  static String time(DateTime value) =>
      DateFormat('h:mm a').format(companyTime(value));
  static String hours(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  static String elapsed(Duration value) {
    final seconds = value.inSeconds.clamp(0, 1 << 32);
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  DateTime get weekStart {
    final local = companyTime(now);
    return fromCompany(
      DateTime(
        local.year,
        local.month,
        local.day,
      ).subtract(Duration(days: local.weekday - 1)),
    );
  }
}
