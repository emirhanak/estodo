import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../utils/planned_layout.dart';

/// Formatting helpers shared by the planned timeline widgets.
class PlannedFormat {
  const PlannedFormat._();

  static final DateFormat _time = DateFormat('HH:mm');

  static String intlLocale(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'tr' ? 'tr_TR' : 'en_US';

  static bool mondayFirst(BuildContext context) =>
      Localizations.localeOf(context).languageCode != 'en';

  static String time(DateTime value) => _time.format(value);

  static String duration(AppLocalizations l10n, int minutes) {
    if (minutes < 60) return l10n.plannedMinutesShort(minutes);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return l10n.plannedHoursShort(hours);
    return '${l10n.plannedHoursShort(hours)} ${l10n.plannedMinutesShort(rest)}';
  }

  /// `08:30 – 09:00 (30 dk)` for scheduled entries.
  static String range(AppLocalizations l10n, PlannedEntry entry) {
    final start = entry.start;
    final end = entry.end;
    if (start == null || end == null) return l10n.allDay;
    return '${time(start)} – ${time(end)} (${duration(l10n, entry.durationMinutes)})';
  }

  static String weekdayShort(DateTime date, String locale) =>
      DateFormat('EEE', locale).format(date).replaceAll('.', '');

  static String monthYear(DateTime date, String locale) =>
      DateFormat('MMMM', locale).format(date);

  static String fullDay(DateTime date, String locale) =>
      DateFormat('EEEE, d MMMM', locale).format(date);
}
