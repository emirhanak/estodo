import 'package:estodo/core/utils/date_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    await initializeDateFormatting('en_US');
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 14, 5);

  test('todayKey uses the storage format', () {
    expect(DateTimeFormatter.todayKey(DateTime(2026, 3, 4)), '2026-03-04');
    expect(
      DateTimeFormatter.isTodayKey('2026-03-04', DateTime(2026, 3, 4, 23)),
      isTrue,
    );
    expect(DateTimeFormatter.isTodayKey(null), isFalse);
  });

  test('dueLabel names relative days in both languages', () {
    expect(DateTimeFormatter.dueLabel(today), 'Today');
    expect(DateTimeFormatter.dueLabel(today, locale: 'tr'), 'Bugün');
    final tomorrow = today.add(const Duration(days: 1));
    expect(DateTimeFormatter.dueLabel(tomorrow), 'Tomorrow');
    expect(DateTimeFormatter.dueLabel(tomorrow, locale: 'tr_TR'), 'Yarın');
    final yesterday = today.subtract(const Duration(days: 1));
    expect(DateTimeFormatter.dueLabel(yesterday), 'Yesterday');
    expect(DateTimeFormatter.dueLabel(yesterday, locale: 'tr'), 'Dün');
  });

  test('dueLabel uses the weekday within a week and a date beyond', () {
    final inThreeDays = today.add(const Duration(days: 3));
    expect(
      DateTimeFormatter.dueLabel(inThreeDays),
      DateFormatWeekday.english[inThreeDays.weekday - 1],
    );
    final far = DateTime(now.year + 1, 1, 5);
    expect(DateTimeFormatter.dueLabel(far, locale: 'tr'), '5 Ocak');
    expect(DateTimeFormatter.dueLabel(far), endsWith('Jan 5'));
  });

  test('reminder, time and full day labels', () {
    expect(DateTimeFormatter.timeLabel(today), '14:05');
    expect(DateTimeFormatter.reminderLabel(today), 'Today 14:05');
    expect(
      DateTimeFormatter.fullDayLabel(DateTime(2026, 10, 7), locale: 'tr'),
      'Çarşamba 7 Ekim',
    );
    expect(
      DateTimeFormatter.fullDayLabel(DateTime(2026, 10, 7)),
      'Wednesday, October 7',
    );
  });

  test('plannedBucket groups by distance from today', () {
    expect(
      DateTimeFormatter.plannedBucket(today.subtract(const Duration(days: 2))),
      PlannedBucket.earlier,
    );
    expect(DateTimeFormatter.plannedBucket(today), PlannedBucket.today);
    expect(
      DateTimeFormatter.plannedBucket(today.add(const Duration(days: 1))),
      PlannedBucket.tomorrow,
    );
    expect(
      DateTimeFormatter.plannedBucket(today.add(const Duration(days: 5))),
      PlannedBucket.thisWeek,
    );
    expect(
      DateTimeFormatter.plannedBucket(today.add(const Duration(days: 30))),
      PlannedBucket.later,
    );
  });
}

abstract final class DateFormatWeekday {
  static const english = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
