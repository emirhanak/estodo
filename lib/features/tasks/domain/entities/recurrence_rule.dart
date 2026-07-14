enum RecurrenceFrequency {
  daily,
  weekdays,
  weekly,
  monthly,
  yearly;

  String get label {
    return switch (this) {
      RecurrenceFrequency.daily => 'Daily',
      RecurrenceFrequency.weekdays => 'Weekdays',
      RecurrenceFrequency.weekly => 'Weekly',
      RecurrenceFrequency.monthly => 'Monthly',
      RecurrenceFrequency.yearly => 'Yearly',
    };
  }
}

class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
  });

  final RecurrenceFrequency frequency;
  final int interval;

  String get label {
    if (interval <= 1) return frequency.label;
    return 'Every $interval ${frequency.label.toLowerCase()}';
  }

  DateTime nextOccurrence(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: interval));
      case RecurrenceFrequency.weekdays:
        var next = from.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceFrequency.weekly:
        return from.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        final month = from.month + interval;
        final yearAdd = (month - 1) ~/ 12;
        final newMonth = ((month - 1) % 12) + 1;
        final lastDayOfMonth = DateTime(from.year + yearAdd, newMonth + 1, 0).day;
        final day = from.day > lastDayOfMonth ? lastDayOfMonth : from.day;
        return DateTime(
          from.year + yearAdd,
          newMonth,
          day,
          from.hour,
          from.minute,
          from.second,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          from.year + interval,
          from.month,
          from.day,
          from.hour,
          from.minute,
          from.second,
        );
    }
  }

  Map<String, dynamic> toMap() => {
        'frequency': frequency.name,
        'interval': interval,
      };

  static RecurrenceRule? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['frequency'] as String?;
    if (name == null) return null;
    final freq = RecurrenceFrequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => RecurrenceFrequency.daily,
    );
    return RecurrenceRule(
      frequency: freq,
      interval: (data['interval'] as num?)?.toInt() ?? 1,
    );
  }
}
