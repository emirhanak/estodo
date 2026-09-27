import '../../domain/entities/recurrence_rule.dart';

/// What the composer understood from a freely typed title, e.g.
/// `"1 saat yoga cuma 16:00"` → Friday, 16:00, 60 minutes, title "yoga".
class PlannedNlpResult {
  const PlannedNlpResult({
    required this.title,
    this.date,
    this.startMinuteOfDay,
    this.durationMinutes,
    this.recurrence,
    this.allDay = false,
  });

  final String title;
  final DateTime? date;
  final int? startMinuteOfDay;
  final int? durationMinutes;
  final RecurrenceRule? recurrence;
  final bool allDay;

  bool get isEmpty =>
      date == null &&
      startMinuteOfDay == null &&
      durationMinutes == null &&
      recurrence == null &&
      !allDay;
}

/// Turkish + English natural language parsing for the planned composer.
///
/// Deliberately conservative: a fragment is only consumed when it is a clear
/// date, time, duration or repeat phrase, so ordinary titles stay untouched.
class PlannedNlp {
  const PlannedNlp._();

  /// Default rhythm a habit starts with.
  static const dailyRule = RecurrenceRule(frequency: RecurrenceFrequency.daily);

  static const _weekdayWords = <String, int>{
    'pazartesi': DateTime.monday,
    'salı': DateTime.tuesday,
    'sali': DateTime.tuesday,
    'çarşamba': DateTime.wednesday,
    'carsamba': DateTime.wednesday,
    'perşembe': DateTime.thursday,
    'persembe': DateTime.thursday,
    'cuma': DateTime.friday,
    'cumartesi': DateTime.saturday,
    'pazar': DateTime.sunday,
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  static PlannedNlpResult parse(String input, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    var text = ' ${input.trim()} ';
    if (text.trim().isEmpty) {
      return PlannedNlpResult(title: input.trim());
    }

    DateTime? date;
    int? startMinute;
    int? duration;
    RecurrenceRule? recurrence;
    var allDay = false;

    String consume(RegExp pattern) {
      final match = pattern.firstMatch(text);
      if (match == null) return '';
      text = text.replaceRange(match.start, match.end, ' ');
      return match.group(0)!;
    }

    // Repeat: "her gün", "her hafta", "hafta içi", "every monday", "daily".
    final repeatMatch = RegExp(
      r'\b(her\s+g[üu]n|her\s+hafta|her\s+ay|hafta\s+i[çc]i|daily|weekly|monthly|every\s+day|every\s+week|every\s+month)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (repeatMatch != null) {
      final phrase = repeatMatch.group(1)!.toLowerCase();
      recurrence = RecurrenceRule(
        frequency: switch (phrase) {
          final p when p.contains('ay') || p.contains('month') =>
            RecurrenceFrequency.monthly,
          final p when p.contains('hafta i') => RecurrenceFrequency.weekdays,
          final p when p.contains('hafta') || p.contains('week') =>
            RecurrenceFrequency.weekly,
          _ => RecurrenceFrequency.daily,
        },
      );
      text = text.replaceRange(repeatMatch.start, repeatMatch.end, ' ');
    }

    // Duration: "1 saat", "45 dk", "1.5h", "90 min".
    final durationMatch = RegExp(
      r'\b(\d{1,3})(?:[.,](\d))?\s*(saat|sa|dakika|dk|dak|hours?|hrs?|h|minutes?|mins?|m)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (durationMatch != null) {
      final whole = int.parse(durationMatch.group(1)!);
      final fraction = durationMatch.group(2);
      final unit = durationMatch.group(3)!.toLowerCase();
      final isHour = unit == 'sa' ||
          unit == 'saat' ||
          unit == 'h' ||
          unit.startsWith('hour') ||
          unit.startsWith('hr');
      if (isHour) {
        duration =
            whole * 60 + (fraction == null ? 0 : int.parse(fraction) * 6);
      } else {
        duration = whole;
      }
      text = text.replaceRange(durationMatch.start, durationMatch.end, ' ');
    }

    // Explicit clock time: "16:00", "saat 9", "at 4".
    final clockMatch = RegExp(
      r'\b(?:saat\s+|at\s+)?([01]?\d|2[0-3])[:.](\d{2})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (clockMatch != null) {
      startMinute = int.parse(clockMatch.group(1)!) * 60 +
          int.parse(clockMatch.group(2)!);
      text = text.replaceRange(clockMatch.start, clockMatch.end, ' ');
    } else {
      final looseMatch = RegExp(
        r'\b(?:saat|at)\s+([01]?\d|2[0-3])\b',
        caseSensitive: false,
      ).firstMatch(text);
      if (looseMatch != null) {
        var hour = int.parse(looseMatch.group(1)!);
        // "at 4" in the afternoon reads as 16:00, like Structured does.
        if (hour < 7) hour += 12;
        startMinute = hour * 60;
        text = text.replaceRange(looseMatch.start, looseMatch.end, ' ');
      }
    }

    // Relative days.
    final today = DateTime(clock.year, clock.month, clock.day);
    if (consume(RegExp(r'\b(bug[üu]n|today)\b', caseSensitive: false))
        .isNotEmpty) {
      date = today;
    } else if (consume(RegExp(r'\b(yar[ıi]n|tomorrow)\b', caseSensitive: false))
        .isNotEmpty) {
      date = today.add(const Duration(days: 1));
    } else {
      for (final entry in _weekdayWords.entries) {
        final match =
            RegExp('\\b${entry.key}\\b', caseSensitive: false).firstMatch(text);
        if (match == null) continue;
        var delta = (entry.value - today.weekday) % 7;
        if (delta == 0) delta = 7;
        date = today.add(Duration(days: delta));
        text = text.replaceRange(match.start, match.end, ' ');
        if (recurrence?.frequency == RecurrenceFrequency.weekly) {
          recurrence = recurrence!.copyWith(weekdays: [entry.value]);
        }
        break;
      }
    }

    if (consume(
            RegExp(r'\b(t[üu]m\s+g[üu]n|all\s*day)\b', caseSensitive: false))
        .isNotEmpty) {
      allDay = true;
      startMinute = null;
    }

    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,;-]+|[\s,;-]+$'), '')
        .trim();

    return PlannedNlpResult(
      title: cleaned.isEmpty ? input.trim() : cleaned,
      date: date,
      startMinuteOfDay: startMinute,
      durationMinutes: duration,
      recurrence: recurrence,
      allDay: allDay,
    );
  }
}
