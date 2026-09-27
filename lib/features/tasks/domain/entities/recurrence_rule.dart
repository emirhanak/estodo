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
    this.weekdays = const <int>[],
    this.until,
  });

  final RecurrenceFrequency frequency;
  final int interval;

  /// Weekdays (`DateTime.monday`..`DateTime.sunday`) a weekly rule repeats on.
  /// Empty means "the same weekday as the task itself".
  final List<int> weekdays;

  /// Last day the rule may produce an occurrence on, or null for open ended.
  final DateTime? until;

  String get label {
    if (interval <= 1) return frequency.label;
    return 'Every $interval ${frequency.label.toLowerCase()}';
  }

  bool get hasEnd => until != null;

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? weekdays,
    Object? until = _unset,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      until: until == _unset ? this.until : until as DateTime?,
    );
  }

  /// The next date the rule fires after [from], or null once [until] passed.
  DateTime? nextOccurrenceOrNull(DateTime from) {
    final next = nextOccurrence(from);
    final end = until;
    if (end == null) return next;
    final lastDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return next.isAfter(lastDay) ? null : next;
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
        if (weekdays.isEmpty) {
          return from.add(Duration(days: 7 * interval));
        }
        return _nextSelectedWeekday(from);
      case RecurrenceFrequency.monthly:
        final month = from.month + interval;
        final yearAdd = (month - 1) ~/ 12;
        final newMonth = ((month - 1) % 12) + 1;
        final lastDayOfMonth =
            DateTime(from.year + yearAdd, newMonth + 1, 0).day;
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

  /// Walks forward to the next selected weekday, skipping [interval] - 1 weeks
  /// once the current week is exhausted.
  DateTime _nextSelectedWeekday(DateTime from) {
    final selected = weekdays.toSet();
    var cursor = from;
    for (var i = 0; i < 7; i++) {
      cursor = cursor.add(const Duration(days: 1));
      if (!selected.contains(cursor.weekday)) continue;
      if (interval <= 1) return cursor;
      // A longer interval only allows the same week once the cycle restarts.
      final crossedWeek = cursor.weekday < from.weekday;
      if (!crossedWeek) return cursor;
      return cursor.add(Duration(days: 7 * (interval - 1)));
    }
    return from.add(Duration(days: 7 * interval));
  }

  Map<String, dynamic> toMap() => {
        'frequency': frequency.name,
        'interval': interval,
        if (weekdays.isNotEmpty) 'weekdays': weekdays,
        if (until != null) 'until': until!.toIso8601String(),
      };

  static RecurrenceRule? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['frequency'] as String?;
    if (name == null) return null;
    final freq = RecurrenceFrequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => RecurrenceFrequency.daily,
    );
    final rawDays = data['weekdays'];
    final days = rawDays is List
        ? rawDays
            .map((value) => (value as num?)?.toInt())
            .whereType<int>()
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toList()
        : const <int>[];
    final rawUntil = data['until'];
    return RecurrenceRule(
      frequency: freq,
      interval: (data['interval'] as num?)?.toInt() ?? 1,
      weekdays: days,
      until: rawUntil is String ? DateTime.tryParse(rawUntil) : null,
    );
  }
}

const _unset = Object();
