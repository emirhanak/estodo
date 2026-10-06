import '../../../l10n/app_localizations.dart';
import '../domain/entities/app_user.dart';

/// Marker the auth repository stores as the display name of guest users.
const guestDisplayNameMarker = 'Guest';

extension AppUserDisplay on AppUser {
  bool get _hasOwnName =>
      displayName != null &&
      displayName!.trim().isNotEmpty &&
      !(isAnonymous && displayName == guestDisplayNameMarker);

  /// Name to show in the UI; guests get the localized "Guest" label.
  String visibleName(AppLocalizations l10n) {
    if (_hasOwnName) return displayName!;
    if (isAnonymous || email.isEmpty) return l10n.guestName;
    return email;
  }

  /// First name for greetings ("Good morning, Emir").
  String shortName(AppLocalizations l10n) {
    if (_hasOwnName) return displayName!.trim().split(' ').first;
    if (isAnonymous || email.isEmpty) return l10n.guestName;
    return email.split('@').first;
  }
}
