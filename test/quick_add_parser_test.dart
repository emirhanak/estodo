import 'package:flutter_test/flutter_test.dart';
import 'package:estodo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:estodo/features/tasks/presentation/utils/quick_add_parser.dart';

void main() {
  final now = DateTime(2026, 8, 16, 8, 0);

  test('parses Turkish tomorrow time and removes metadata from title', () {
    final result = parseQuickAdd("yarın 9'da Ahmet'i ara", now: now);

    expect(result.title, "Ahmet'i ara");
    expect(result.dueAt, DateTime(2026, 8, 17, 9));
    expect(result.reminderAt, DateTime(2026, 8, 17, 9));
  });

  test('parses weekday recurrence', () {
    final result = parseQuickAdd('hafta içi raporu gönder', now: now);

    expect(result.title, 'raporu gönder');
    expect(result.recurrence?.frequency, RecurrenceFrequency.weekdays);
    expect(result.dueAt, DateTime(2026, 8, 16));
  });
}
