import 'package:estodo/features/tasks/presentation/utils/calendar_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses timed and all-day iCalendar events', () {
    const source = '''BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Project review
DTSTART:20260822T093000
DTEND:20260822T104500
DESCRIPTION:Bring notes\\nSecond line
END:VEVENT
BEGIN:VEVENT
SUMMARY:Holiday
DTSTART;VALUE=DATE:20260823
DTEND;VALUE=DATE:20260824
END:VEVENT
END:VCALENDAR''';

    final events = CalendarImport.parse(source);

    expect(events, hasLength(2));
    expect(events.first.title, 'Project review');
    expect(events.first.startAt, DateTime(2026, 8, 22, 9, 30));
    expect(events.first.dueAt, DateTime(2026, 8, 22));
    expect(events.first.durationMinutes, 75);
    expect(events.first.notes, 'Bring notes\nSecond line');
    expect(events.last.startAt, isNull);
    expect(events.last.dueAt, DateTime(2026, 8, 23));
  });

  test('unfolds continued properties and skips invalid events', () {
    const source = '''BEGIN:VEVENT
SUMMARY:A long event
 title
DTSTART:20260822T120000
END:VEVENT
BEGIN:VEVENT
SUMMARY:Missing date
END:VEVENT''';

    final events = CalendarImport.parse(source);

    expect(events, hasLength(1));
    expect(events.single.title, 'A long eventtitle');
    expect(events.single.durationMinutes, 30);
  });
}
