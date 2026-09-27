import 'package:estodo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_draft.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_nlp.dart';
import 'package:estodo/features/tasks/presentation/utils/task_icon_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Wednesday, so weekday maths is easy to read.
  final now = DateTime(2026, 9, 9, 8, 20);

  group('PlannedNlp', () {
    test('reads duration, weekday and clock time out of a title', () {
      final result = PlannedNlp.parse('1 saat yoga cuma 16:00', now: now);

      expect(result.title, 'yoga');
      expect(result.durationMinutes, 60);
      expect(result.startMinuteOfDay, 16 * 60);
      expect(result.date, DateTime(2026, 9, 11));
    });

    test('understands English phrasing', () {
      final result = PlannedNlp.parse('45 min review tomorrow at 9', now: now);

      expect(result.title, 'review');
      expect(result.durationMinutes, 45);
      expect(result.startMinuteOfDay, 9 * 60);
      expect(result.date, DateTime(2026, 9, 10));
    });

    test('reads half hours written with a decimal', () {
      final result = PlannedNlp.parse('1.5 saat ders', now: now);

      expect(result.durationMinutes, 90);
      expect(result.title, 'ders');
    });

    test('turns "her gün" into a daily rule', () {
      final result = PlannedNlp.parse('her gün su iç', now: now);

      expect(result.recurrence?.frequency, RecurrenceFrequency.daily);
      expect(result.title, 'su iç');
    });

    test('pins a weekly rule to the named weekday', () {
      final result = PlannedNlp.parse('her hafta pazartesi spor', now: now);

      expect(result.recurrence?.frequency, RecurrenceFrequency.weekly);
      expect(result.recurrence?.weekdays, [DateTime.monday]);
    });

    test('marks all-day phrases', () {
      final result = PlannedNlp.parse('tüm gün taşınma', now: now);

      expect(result.allDay, isTrue);
      expect(result.startMinuteOfDay, isNull);
    });

    test('leaves an ordinary title untouched', () {
      final result = PlannedNlp.parse('Anneme hediye al', now: now);

      expect(result.isEmpty, isTrue);
      expect(result.title, 'Anneme hediye al');
    });

    test('keeps the title when it is only a time phrase', () {
      final result = PlannedNlp.parse('16:00', now: now);

      expect(result.startMinuteOfDay, 16 * 60);
      expect(result.title, '16:00');
    });
  });

  group('PlannedDraft', () {
    PlannedDraft draft() => PlannedDraft(
          title: 'Yoga',
          date: DateTime(2026, 9, 9),
          colorValue: 0xFF8E8CD8,
          startMinuteOfDay: 9 * 60,
          durationMinutes: 45,
        );

    test('derives start, end and due from the day and minute offset', () {
      final value = draft();

      expect(value.startAt, DateTime(2026, 9, 9, 9));
      expect(value.endAt, DateTime(2026, 9, 9, 9, 45));
      expect(value.dueAt, DateTime(2026, 9, 9, 9));
      expect(value.isAllDay, isFalse);
    });

    test('an all-day draft drops the time but keeps the day', () {
      final value = draft().copyWith(startMinuteOfDay: null);

      expect(value.isAllDay, isTrue);
      expect(value.startAt, isNull);
      expect(value.dueAt, DateTime(2026, 9, 9));
    });

    test('reminder lead time counts back from the start', () {
      final value = draft().copyWith(reminderMinutesBefore: 15);

      expect(value.reminderAt, DateTime(2026, 9, 9, 8, 45));
    });

    test('an all-day reminder fires in the morning', () {
      final value =
          draft().copyWith(startMinuteOfDay: null, reminderMinutesBefore: 0);

      expect(value.reminderAt, DateTime(2026, 9, 9, 9));
    });

    test('empty titles cannot be saved', () {
      expect(draft().copyWith(title: '   ').canSave, isFalse);
      expect(draft().canSave, isTrue);
    });

    test('a new habit draft starts with a daily rhythm', () {
      final value = PlannedDraft.forDate(
        DateTime(2026, 9, 11),
        colorValue: 0xFF8E8CD8,
        now: now,
        kind: PlannedDraftKind.habit,
      );

      expect(value.isHabit, isTrue);
      expect(value.recurrence?.frequency, RecurrenceFrequency.daily);
      expect(value.startAt, DateTime(2026, 9, 11, 9));
    });

    test('applyNlp folds the parsed title, day, time and length in', () {
      final value = draft()
          .copyWith(title: '1 saat yoga cuma 16:00')
          .applyNlp(PlannedNlp.parse('1 saat yoga cuma 16:00', now: now));

      expect(value.title, 'yoga');
      expect(value.date, DateTime(2026, 9, 11));
      expect(value.startMinuteOfDay, 16 * 60);
      expect(value.durationMinutes, 60);
    });

    test('applyTo keeps task identity and writes the schedule', () {
      final task = TodoTask(
        id: 't1',
        userId: 'u',
        title: 'Old',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = draft()
          .copyWith(iconKey: 'yoga', reminderMinutesBefore: 0)
          .applyTo(task);

      expect(updated.id, 't1');
      expect(updated.isCompleted, isTrue);
      expect(updated.title, 'Yoga');
      expect(updated.iconKey, 'yoga');
      expect(updated.colorValue, 0xFF8E8CD8);
      expect(updated.startAt, DateTime(2026, 9, 9, 9));
      expect(updated.durationMinutes, 45);
      expect(updated.reminderAt, DateTime(2026, 9, 9, 9));
    });

    test('fromTask round-trips an existing task', () {
      final task = TodoTask(
        id: 't1',
        userId: 'u',
        title: 'Koşu',
        iconKey: 'run',
        colorValue: 0xFF107C10,
        isHabit: true,
        dueAt: DateTime(2026, 9, 9),
        startAt: DateTime(2026, 9, 9, 7, 30),
        durationMinutes: 30,
        reminderAt: DateTime(2026, 9, 9, 7, 15),
        createdAt: now,
        updatedAt: now,
      );

      final value = PlannedDraft.fromTask(task, fallbackColor: 0xFF8E8CD8);

      expect(value.kind, PlannedDraftKind.habit);
      expect(value.colorValue, 0xFF107C10);
      expect(value.iconKey, 'run');
      expect(value.startMinuteOfDay, 7 * 60 + 30);
      expect(value.durationMinutes, 30);
      expect(value.reminderMinutesBefore, 15);
    });
  });

  group('RecurrenceRule', () {
    test('weekly rules walk to the next selected weekday', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );

      // Wednesday -> Friday -> Monday.
      expect(rule.nextOccurrence(DateTime(2026, 9, 9)), DateTime(2026, 9, 11));
      expect(rule.nextOccurrence(DateTime(2026, 9, 11)), DateTime(2026, 9, 14));
    });

    test('weekly rules without weekdays keep the interval', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      );

      expect(rule.nextOccurrence(DateTime(2026, 9, 9)), DateTime(2026, 9, 23));
    });

    test('an end date stops the series', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        until: DateTime(2026, 9, 10),
      );

      expect(
        rule.nextOccurrenceOrNull(DateTime(2026, 9, 9)),
        DateTime(2026, 9, 10),
      );
      expect(rule.nextOccurrenceOrNull(DateTime(2026, 9, 10)), isNull);
    });

    test('weekdays and end date survive a map round-trip', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        weekdays: const [DateTime.tuesday, DateTime.thursday],
        until: DateTime(2026, 12, 31),
      );

      final restored = RecurrenceRule.fromMap(rule.toMap());

      expect(restored?.frequency, RecurrenceFrequency.weekly);
      expect(restored?.interval, 2);
      expect(restored?.weekdays, [DateTime.tuesday, DateTime.thursday]);
      expect(restored?.until, DateTime(2026, 12, 31));
    });
  });

  group('TaskIconCatalog', () {
    test('suggests an icon from Turkish and English titles', () {
      expect(TaskIconCatalog.suggestKeys('Sabah koşusu').first, 'run');
      expect(TaskIconCatalog.suggestKeys('Team meeting').first, 'meeting');
      expect(TaskIconCatalog.suggestKeys('Fatura öde').first, 'payment');
    });

    test('search matches keys and keywords', () {
      expect(
        TaskIconCatalog.search('kahve').map((entry) => entry.key),
        contains('coffee'),
      );
      expect(TaskIconCatalog.search('zzzz'), isEmpty);
    });

    test('unknown keys fall back to a safe glyph', () {
      expect(TaskIconCatalog.entryFor('nope'), isNull);
      expect(
        TaskIconCatalog.resolve('nope'),
        TaskIconCatalog.resolve(TaskIconCatalog.fallbackKey),
      );
    });
  });
}
