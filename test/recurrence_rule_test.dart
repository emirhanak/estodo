import 'package:estodo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 2026-10-07 09:30.
  final wednesday = DateTime(2026, 10, 7, 9, 30);

  group('nextOccurrence', () {
    test('daily adds the interval in days', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
      );
      expect(rule.nextOccurrence(wednesday), DateTime(2026, 10, 10, 9, 30));
    });

    test('weekdays skips the weekend', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekdays);
      expect(rule.nextOccurrence(DateTime(2026, 10, 9, 8)),
          DateTime(2026, 10, 12, 8));
      expect(rule.nextOccurrence(wednesday), DateTime(2026, 10, 8, 9, 30));
    });

    test('weekly without weekdays repeats on the same weekday', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      );
      expect(rule.nextOccurrence(wednesday), DateTime(2026, 10, 21, 9, 30));
    });

    test('weekly with weekdays picks the next selected day this week', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: [DateTime.monday, DateTime.friday],
      );
      expect(rule.nextOccurrence(wednesday), DateTime(2026, 10, 9, 9, 30));
    });

    test('weekly interval skips weeks once the week wraps around', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        weekdays: [DateTime.monday],
      );
      // The next Monday is 10-12; a two-week interval moves it to 10-19.
      expect(rule.nextOccurrence(wednesday), DateTime(2026, 10, 19, 9, 30));
    });

    test('monthly clamps to the last day of shorter months', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      expect(
        rule.nextOccurrence(DateTime(2026, 1, 31, 7)),
        DateTime(2026, 2, 28, 7),
      );
    });

    test('monthly rolls over into the next year', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 3,
      );
      expect(
        rule.nextOccurrence(DateTime(2026, 11, 15)),
        DateTime(2027, 2, 15),
      );
    });

    test('yearly adds the interval in years', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.yearly);
      expect(rule.nextOccurrence(wednesday), DateTime(2027, 10, 7, 9, 30));
    });
  });

  group('nextOccurrenceOrNull', () {
    test('returns the occurrence on the last allowed day', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        until: DateTime(2026, 10, 8),
      );
      expect(rule.nextOccurrenceOrNull(wednesday), isNotNull);
    });

    test('returns null once the end date has passed', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        until: DateTime(2026, 10, 7),
      );
      expect(rule.nextOccurrenceOrNull(wednesday), isNull);
    });

    test('is open ended without an end date', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
      expect(rule.hasEnd, isFalse);
      expect(rule.nextOccurrenceOrNull(wednesday), isNotNull);
    });
  });

  group('serialization', () {
    test('round-trips through a map', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        weekdays: const [DateTime.monday, DateTime.thursday],
        until: DateTime(2026, 12, 31),
      );
      final restored = RecurrenceRule.fromMap(rule.toMap())!;
      expect(restored.frequency, rule.frequency);
      expect(restored.interval, 2);
      expect(restored.weekdays, rule.weekdays);
      expect(restored.until, rule.until);
    });

    test('drops invalid weekdays and tolerates unknown values', () {
      final rule = RecurrenceRule.fromMap({
        'frequency': 'fortnightly',
        'weekdays': [0, 3, 9, null],
        'until': 'not a date',
      })!;
      expect(rule.frequency, RecurrenceFrequency.daily);
      expect(rule.weekdays, [3]);
      expect(rule.until, isNull);
      expect(rule.interval, 1);
    });

    test('returns null without a frequency', () {
      expect(RecurrenceRule.fromMap(null), isNull);
      expect(RecurrenceRule.fromMap({'interval': 2}), isNull);
    });
  });

  test('copyWith can clear the end date', () {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
      until: DateTime(2026, 12, 31),
    );
    expect(rule.copyWith(until: null).until, isNull);
    expect(rule.copyWith(interval: 2).until, rule.until);
  });

  test('labels describe the interval', () {
    expect(
      const RecurrenceRule(frequency: RecurrenceFrequency.weekly).label,
      'Weekly',
    );
    expect(
      const RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: 2)
          .label,
      'Every 2 daily',
    );
  });
}
