import 'package:estodo/features/onboarding/onboarding_cards_scene.dart';
import 'package:estodo/features/onboarding/onboarding_timeline_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('cards appear one by one, then report revealed', (tester) async {
    var revealed = false;
    await tester.pumpWidget(_host(OnboardingCardsScene(
      phase: CardsPhase.scatter,
      onRevealed: () => revealed = true,
    )));

    await tester.pump(const Duration(seconds: 1));
    expect(revealed, isFalse);

    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(revealed, isTrue);
    expect(find.text('Sabah koşusu'), findsOneWidget);
  });

  testWidgets('cards fall and clear without errors', (tester) async {
    Widget scene(CardsPhase phase) =>
        _host(OnboardingCardsScene(phase: phase, onRevealed: () {}));

    await tester.pumpWidget(scene(CardsPhase.scatter));
    await tester.pumpWidget(scene(CardsPhase.fall));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(scene(CardsPhase.gone));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline rows fill in and get checked', (tester) async {
    await tester.pumpWidget(_host(const OnboardingTimelineScene()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Odak zamanı'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));
  });
}
