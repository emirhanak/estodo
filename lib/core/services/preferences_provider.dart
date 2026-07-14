import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';

const _kAccentKey = 'pref.accent_color';
const _kOnboardingKey = 'pref.onboarding_seen';
const _kHiddenSmartListsKey = 'pref.hidden_smart_lists';
const _kConfettiKey = 'pref.confetti_enabled';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final accentColorProvider =
    NotifierProvider<AccentColorController, Color>(AccentColorController.new);

class AccentColorController extends Notifier<Color> {
  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider).value;
    final value = prefs?.getInt(_kAccentKey);
    if (value == null) return AppTheme.seed;
    return Color(value);
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = ref.read(sharedPreferencesProvider).value;
    await prefs?.setInt(_kAccentKey, color.toARGB32());
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenController, bool>(
  OnboardingSeenController.new,
);

class OnboardingSeenController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider).value;
    return prefs?.getBool(_kOnboardingKey) ?? false;
  }

  Future<void> markSeen() async {
    state = true;
    final prefs = ref.read(sharedPreferencesProvider).value;
    await prefs?.setBool(_kOnboardingKey, true);
  }
}

final hiddenSmartListsProvider =
    NotifierProvider<HiddenSmartListsController, Set<String>>(
  HiddenSmartListsController.new,
);

class HiddenSmartListsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider).value;
    return (prefs?.getStringList(_kHiddenSmartListsKey) ?? const <String>[])
        .toSet();
  }

  Future<void> toggle(String key) async {
    final next = Set<String>.from(state);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = next;
    final prefs = ref.read(sharedPreferencesProvider).value;
    await prefs?.setStringList(_kHiddenSmartListsKey, next.toList());
  }
}

final confettiEnabledProvider =
    NotifierProvider<ConfettiController, bool>(ConfettiController.new);

class ConfettiController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider).value;
    return prefs?.getBool(_kConfettiKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider).value;
    await prefs?.setBool(_kConfettiKey, value);
  }
}
