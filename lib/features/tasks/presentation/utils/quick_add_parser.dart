import '../../domain/entities/recurrence_rule.dart';

class ParsedQuickAdd {
  const ParsedQuickAdd({
    required this.title,
    this.dueAt,
    this.reminderAt,
    this.recurrence,
  });

  final String title;
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final RecurrenceRule? recurrence;
}

/// Small, deterministic Turkish parser for the most common quick-add phrases.
/// It intentionally stays local and predictable; advanced editing remains in
/// the task sheet.
ParsedQuickAdd parseQuickAdd(String input, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  var title = input.trim();
  DateTime? date;
  DateTime? time;
  RecurrenceRule? recurrence;

  final recurrencePatterns = <RegExp, RecurrenceRule>{
    RegExp(r'\bher\s*g[uü]n\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.daily),
    RegExp(r'\bhafta\s*i[çc]i\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.weekdays),
    RegExp(r'\bher\s*pazartesi\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
    RegExp(r'\bher\s*hafta\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
    RegExp(r'\bher\s*ay\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
    RegExp(r'\bher\s*y[ıi]l\b', caseSensitive: false):
        const RecurrenceRule(frequency: RecurrenceFrequency.yearly),
  };
  for (final entry in recurrencePatterns.entries) {
    if (entry.key.hasMatch(title)) {
      recurrence = entry.value;
      title = title.replaceFirst(entry.key, '');
      break;
    }
  }

  final relativeDate = RegExp(r'\b(yar[ıi]n|bug[uü]n)\b', caseSensitive: false)
      .firstMatch(title);
  if (relativeDate != null) {
    date = DateTime(
        clock.year,
        clock.month,
        clock.day,
        relativeDate.group(1)!.toLowerCase().startsWith('yar') ? 0 : clock.hour,
        relativeDate.group(1)!.toLowerCase().startsWith('yar')
            ? 0
            : clock.minute);
    if (relativeDate.group(1)!.toLowerCase().startsWith('yar')) {
      date = date.add(const Duration(days: 1));
    }
    title = title.replaceFirst(relativeDate.group(0)!, '');
  }

  final clockMatch = RegExp(
          r"\b(?:saat\s*)?(\d{1,2})(?:[:.](\d{2}))?\s*(?:da|de|'da|'de)?\b",
          caseSensitive: false)
      .firstMatch(title);
  if (clockMatch != null) {
    final hour = int.parse(clockMatch.group(1)!);
    final minute = int.tryParse(clockMatch.group(2) ?? '0') ?? 0;
    if (hour < 24 && minute < 60) {
      time = DateTime(2000, 1, 1, hour, minute);
      title = title.replaceFirst(clockMatch.group(0)!, '');
    }
  }

  if (date == null && time != null) {
    date = DateTime(clock.year, clock.month, clock.day);
  }
  if (date != null && time != null) {
    date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  if (recurrence != null && date == null) {
    date = DateTime(clock.year, clock.month, clock.day);
  }

  title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return ParsedQuickAdd(
    title: title,
    dueAt: date,
    reminderAt: time == null ? null : date,
    recurrence: recurrence,
  );
}
