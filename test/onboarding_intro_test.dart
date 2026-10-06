import 'package:estodo/features/onboarding/onboarding_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required VoidCallback onContinue}) => MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: OnboardingIntro(onContinue: onContinue, onSignIn: () {}),
      );

  testWidgets('cards appear one by one, then continue works', (tester) async {
    var continued = false;
    await tester.pumpWidget(host(onContinue: () => continued = true));

    // Starts empty: the continue button is hidden and not tappable.
    await tester.tap(find.text('Devam et'), warnIfMissed: false);
    expect(continued, isFalse);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sabah koşusu'), findsOneWidget);
    await tester.tap(find.text('Devam et'));
    expect(continued, isTrue);
  });
}
