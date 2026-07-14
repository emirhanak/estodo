import 'package:intl/intl.dart';

class DateTimeFormatter {
  const DateTimeFormatter._();

  static final DateFormat _storageDay = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeLabel = DateFormat('HH:mm');

  static String todayKey([DateTime? now]) =>
      _storageDay.format(now ?? DateTime.now());

  static String dueLabel(DateTime value, {String? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final diff = target.difference(today).inDays;
    final isTr = (locale ?? '').startsWith('tr');
    if (diff == 0) return isTr ? 'Bugün' : 'Today';
    if (diff == 1) return isTr ? 'Yarın' : 'Tomorrow';
    if (diff == -1) return isTr ? 'Dün' : 'Yesterday';
    if (diff > 1 && diff < 7) {
      return DateFormat('EEEE', locale).format(value);
    }
    return DateFormat('EEE, MMM d', locale).format(value);
  }

  static String reminderLabel(DateTime value, {String? locale}) {
    return '${dueLabel(value, locale: locale)} ${_timeLabel.format(value)}';
  }

  static String fullDayLabel(DateTime value, {String? locale}) {
    return DateFormat('EEEE, MMMM d', locale).format(value);
  }

  static String timeLabel(DateTime value) => _timeLabel.format(value);

  static bool isTodayKey(String? key, [DateTime? now]) {
    return key == todayKey(now);
  }

  static PlannedBucket plannedBucket(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return PlannedBucket.earlier;
    if (diff == 0) return PlannedBucket.today;
    if (diff == 1) return PlannedBucket.tomorrow;
    if (diff <= 7) return PlannedBucket.thisWeek;
    return PlannedBucket.later;
  }
}

enum PlannedBucket {
  earlier,
  today,
  tomorrow,
  thisWeek,
  later,
}
