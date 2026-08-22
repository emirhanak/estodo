import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class CalendarImportEvent {
  const CalendarImportEvent({
    required this.title,
    required this.dueAt,
    this.startAt,
    this.durationMinutes,
    this.notes,
  });

  final String title;
  final DateTime dueAt;
  final DateTime? startAt;
  final int? durationMinutes;
  final String? notes;
}

class CalendarImport {
  const CalendarImport._();

  static List<CalendarImportEvent> parseBytes(List<int> bytes) =>
      parse(utf8.decode(bytes, allowMalformed: true));

  static List<CalendarImportEvent> parse(String source) {
    final unfolded = source
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n[ \t]'), '')
        .split('\n');
    final events = <CalendarImportEvent>[];
    Map<String, String>? current;

    for (final raw in unfolded) {
      final line = raw.trimRight();
      if (line == 'BEGIN:VEVENT') {
        current = <String, String>{};
        continue;
      }
      if (line == 'END:VEVENT') {
        if (current != null) {
          final parsed = _eventOf(current);
          if (parsed != null) events.add(parsed);
        }
        current = null;
        continue;
      }
      if (current == null) continue;
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final property = line.substring(0, colon);
      final name = property.split(';').first.toUpperCase();
      current[name] = line.substring(colon + 1);
      if (property.toUpperCase().contains('VALUE=DATE')) {
        current['${name}_ALL_DAY'] = 'true';
      }
    }
    return events;
  }

  static CalendarImportEvent? _eventOf(Map<String, String> data) {
    final title = _unescape(data['SUMMARY'] ?? '').trim();
    final rawStart = data['DTSTART'];
    if (title.isEmpty || rawStart == null) return null;
    final start = _parseDate(rawStart);
    if (start == null) return null;
    final allDay = data['DTSTART_ALL_DAY'] == 'true' || !rawStart.contains('T');
    final end = data['DTEND'] == null ? null : _parseDate(data['DTEND']!);
    final duration = end?.difference(start).inMinutes;
    return CalendarImportEvent(
      title: title,
      dueAt: DateTime(start.year, start.month, start.day),
      startAt: allDay ? null : start,
      durationMinutes:
          allDay ? null : (duration != null && duration > 0 ? duration : 30),
      notes: data['DESCRIPTION'] == null
          ? null
          : _unescape(data['DESCRIPTION']!).trim(),
    );
  }

  static DateTime? _parseDate(String value) {
    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?)?(Z)?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final parts = [
      for (var i = 1; i <= 6; i++) int.tryParse(match.group(i) ?? '')
    ];
    final local = DateTime(
      parts[0]!,
      parts[1]!,
      parts[2]!,
      parts[3] ?? 0,
      parts[4] ?? 0,
      parts[5] ?? 0,
    );
    if (match.group(7) != null) {
      return DateTime.utc(
        parts[0]!,
        parts[1]!,
        parts[2]!,
        parts[3] ?? 0,
        parts[4] ?? 0,
        parts[5] ?? 0,
      ).toLocal();
    }
    return local;
  }

  static String _unescape(String value) => value
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\N', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');
}
