import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';

class MyDayBanner extends ConsumerWidget {
  const MyDayBanner({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final greeting = _greeting(now.hour, l10n);
    final name = (user?.displayName?.split(' ').first ?? user?.email.split('@').first) ?? '';
    final dateLabel = DateTimeFormatter.fullDayLabel(now, locale: locale);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting${name.isEmpty ? '' : ', $name'}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour, AppLocalizations l10n) {
    if (hour < 5) return l10n.greetingNight;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    if (hour < 21) return l10n.greetingEvening;
    return l10n.greetingNight;
  }
}
